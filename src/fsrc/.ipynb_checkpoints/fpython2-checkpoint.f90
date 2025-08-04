
!! new code update

! new python namelist options
! prior_inflate = 0: no prior, 1: Miyoshi (traditional AI), 2: fixed AI value

! post_inflate = 0: nothing, 1: RTPS fixed alpha, 2: RTPS + adapt, 3: RTPP fixed alpha, 4: RTPP +adapt

! post_inflate_alpha = float values. this is the 







!============================================================================================================= 
MODULE INFLATE_PARAMS

! These parameters bind the maximum amount of multiplicative inflation used (LETKF AI and RTPS)

  real(kind=4), parameter :: min_inflate = 0.99, max_inflate = 9.0

! These parameters are for the Relaxation to Prior Spread (RTPS)
! Negative means use adaptive RTPS

  real(kind=4), parameter :: eps = 1.0e-10 ! inflate_RTPS = 1.25,


  real(kind=4), save :: inflate_RTPS = 1.0
  real(kind=4), save :: inflate_RTPP = 1.0
 ! save :: inflate_RTPS, inflate_RTPP


  ! if you use adaptive RTPP, this constrains the relaxation coefficient
  real(kind=4), parameter :: RTPP_base = 0.3
  real(kind=4), parameter :: RTPP_top  = 0.9


! These parameters are for the Relaxation to Prior Perturbation (RTPP)
! Negative means use adaptive RTPP

  !real(kind=4), parameter :: inflate_RTPP = 0.5

! This parameter is for the fixed priors inflation, value > 1 turns off adaptive inflation.
! Normal values of 1.1 --> 1.3 (10% - 30%)

  !real(kind=4), parameter    :: inflate_PRIOR = 1.1
  !integer(kind=4), parameter :: prior_inflate_flag = 1

! Choose whether to run Anderson (2007) RCF 
! Two options:  (1) use RCF in localization matrix within LETKF (expensive)
!               (2) use RCF value and blend with RTPP value from Zhang (2007)

! 2025 update = this code no longer suppors RCF 1. It only uses RCF 2, so the rcf_flag is no longer needed.
! RCF is used if you are using adaptive RTPP or RTPS

  !integer, parameter :: rcf_flag = 0
  integer(kind=4), dimension(5) :: sub_ens = (/5,6,8,10,12/)

! Parameters for the positive definite code in UPDATE
!----------------------------------------------------

  integer, parameter :: pos_def_scheme = 1   ! 0:  NO PD! (override state variable flag)
                                             ! 1:  use standard clipping
                                             ! 2:  use Ooyama (2001) transformation
                                             ! 3:  use ln transformation

  real(kind=4), parameter :: nu0 = 1.0e-7    ! Should be a value between 10^-6 and 10^-8
  real(kind=4), parameter :: nu1 = 1.0e-10   ! 

END MODULE INFLATE_PARAMS

!============================================================================================================= 
MODULE FSTATE

  USE OMP_LIB
  USE INFLATE_PARAMS
  USE COMMON_LETKF

  implicit none
  
! Various

  integer, parameter :: std_out  = 6
  integer, parameter :: std_err  = 7
  integer, parameter :: wordsize = 4

! State variables and parameters
!-------------------------------

! NX     = number of grid zones (not edges) in x-direction.  This is a different convention than NCOMMAS
! NY     = number of grid zones (not edges) in y-direction.  This is a different convention than NCOMMAS
! NZ     = number of grid zones (not edges) in z-direction.  This is a different convention than NCOMMAS
! NE     = number of ensemble members
! NXY2D  = number of 2D variables (current ASSUMED 0 in the code below). 
! NXYZ3D = number of 3D variables 

  integer            :: nx, ny, nz, nxyz3d
  integer            :: ne = 0

  real(kind=wordsize), allocatable, dimension(:)         :: xe, ye, ze
  real(kind=wordsize), allocatable, dimension(:)         :: xc, yc, zc
  real(kind=wordsize), allocatable, dimension(:)         :: latc, late
  real(kind=wordsize), allocatable, dimension(:)         :: lonc, lone
  real(kind=wordsize), allocatable, dimension(:,:)       :: uinit, vinit, thinit, qvinit, piinit
  real(kind=wordsize), allocatable, dimension(:,:,:,:)   :: xy2d
  real(kind=wordsize), allocatable, dimension(:,:,:,:)   :: u, v, w
  real(kind=wordsize), allocatable, dimension(:,:,:,:,:) :: xyz3d
  
  integer, allocatable :: posdef(:)
  integer, allocatable :: var_inflation(:)
  
  real(kind=wordsize)  :: xoffset, yoffset, zoffset

  integer(kind=wordsize) sub_ens_size
  
CONTAINS

!============================================================================================================= 
  SUBROUTINE COMPUTE_LETKF(xob, yob, zob, tob, tanalysis, ob, Hx, dep, rdiag, rloc, rhoriz, rvert, rtime,  &
                           nthreads, cutoff, zcutoff, update_theta, &
                           prior_inflate, in_inflate, post_inflate, post_inflate_alpha, out_inflate, &
                           save_weights, read_weights, fnx, fny, fnz, fnobs, fne) 

! Passed variables

    integer,      intent(IN)    :: fnobs, fne
    integer,      intent(IN)    :: fnx, fny, fnz
    integer,      intent(IN)    :: nthreads
    integer,      intent(IN)    :: cutoff
    integer,      intent(IN)    :: update_theta
    logical,      intent(IN)    :: save_weights
    logical,      intent(IN)    :: read_weights
    real(kind=8), intent(IN)    :: tanalysis, zcutoff
    real(kind=8), intent(IN)    :: rhoriz, rvert, rtime

    real(kind=8), intent(IN)    :: ob(fnobs)
    real(kind=8), intent(IN)    :: Hx(fnobs,fne)
    real(kind=8), intent(IN)    :: dep(fnobs) 
    real(kind=8), intent(IN)    :: rdiag(fnobs)
    real(kind=8), intent(IN)    :: rloc(fnobs)
    real(kind=8), intent(IN)    :: xob(fnobs), yob(fnobs), zob(fnobs), tob(fnobs)

    integer,      intent(IN)    :: prior_inflate  ! various values do various inflation (see below).
    integer,      intent(IN)    :: post_inflate  ! various values do various inflation (see below).
    real(kind=8), intent(IN)    :: post_inflate_alpha
    real(kind=8), intent(IN)    :: in_inflate(fnz,fny,fnx)
    real(kind=8), intent(OUT)   :: out_inflate(fnz,fny,fnx)
        
!-- Local variables

    integer                     :: n, m, i, j, k, nvalid, this_thread
    real(kind=8)                :: x0, y0, z0
    real(kind=4), allocatable   :: var(:), new1(:)
    real(kind=8), allocatable   :: trans(:,:), mean_wgt(:)
    real(kind=8), allocatable   :: obwgt(:)
    integer,      allocatable   :: obindex(:)
    integer                     :: gp_update_count, total_valid_obs
    real(kind=8)                :: t0, t1, t_local, t_letkf, t_core, t_update
    real(kind=4), allocatable   :: trans3D(:,:,:,:,:), mean_wgt3D(:,:,:,:)
    real(kind=8)                :: rcf_mean(nxyz3d), rcf_mean2D(nxyz3d,nz)
    real(kind=8)                :: rcf_coeff(1)


!-- Functions

    real(kind=8)  :: comp_cov_factor    
    
    write(std_out,*) 'COMPUTE_LETKF:  NX/NY/NZ/NE:   ', nx, ny, nz, ne
    write(std_out,*) 'COMPUTE_LETKF:  NOBS:          ', fnobs
    write(std_out,*) 'COMPUTE_LETKF:  X_OB Max/Min:  ', maxval(xob), minval(xob)
    write(std_out,*) 'COMPUTE_LETKF:  Y_OB Max/Min:  ', maxval(yob), minval(yob)
    write(std_out,*) 'COMPUTE_LETKF:  Z_OB Max/Min:  ', maxval(zob), minval(zob)
    write(std_out,*) 'COMPUTE_LETKF:  T_OB Max/Min:  ', maxval(tob), minval(tob)
    write(std_out,*) 'COMPUTE_LETKF:  T_Analysis:    ', tanalysis
    write(std_out,*) 'COMPUTE_LETKF:  X_GD Max/Min:  ', maxval(xc)-xoffset, minval(xc)-xoffset
    write(std_out,*) 'COMPUTE_LETKF:  Y_GD Max/Min:  ', maxval(yc)-yoffset, minval(yc)-yoffset
    write(std_out,*) 'COMPUTE_LETKF:  Z_GD Max/Min:  ', maxval(zc)-zoffset, minval(zc)-zoffset
    write(std_out,*) 'COMPUTE_LETKF:  RHORIZ:        ', rhoriz
    write(std_out,*) 'COMPUTE_LETKF:  RVERT:         ', rvert
    write(std_out,*) 'COMPUTE_LETKF:  RTIME:         ', rtime
    write(std_out,*) 'COMPUTE_LETKF:  Hx shape       ', shape(Hx)
    write(std_out,*) 'COMPUTE_LETKF:  UPDATE THETA FLAG:  ', update_theta
    IF( save_weights ) write(std_out,*) 'COMPUTE_LETKF:  SAVE_WEIGHTS is ON'
    IF( read_weights ) write(std_out,*) 'COMPUTE_LETKF:  READ_WEIGHTS is ON'
    
!-- Allocate local space for LETKF double precision variables

    allocate(var(ne))
    allocate(new1(ne))
    allocate(trans(ne-1,ne-1))
    allocate(mean_wgt(ne-1))
    allocate(obindex(fnobs))
    allocate(obwgt(fnobs))

    IF( save_weights ) THEN
      allocate(trans3D(ne-1,ne-1,fnz,fny,fnx))
      allocate(mean_wgt3D(ne-1,fnz,fny,fnx))
      trans3D     = 0.0
      mean_wgt3D  = 0.0
    ENDIF


    gp_update_count = 0
    total_valid_obs = 0
    t_local         = 0.0
    t_core          = 0.0
    t_update        = 0.0
    rcf_mean(:)     = 0.0

    write(std_out,*) "COMPUTE_LETKF:  NTHREADS:  ", nthreads

! Determine whether we need to compute Anderson's reliability coefficient.  If so, determine sub-group size

    !IF( rcf_flag > 0 ) THEN 
    IF (post_inflate .eq. 2) THEN!IF (post_inflate .eq. 2 .or. post_inflate .eq. 4) THEN
      write(std_out,*) "COMPUTE_LETKF:  ANDERSON'S RELIABILITY COEFFICIENT WILL BE USED IN CALCULATIONS!"
      DO i = size(sub_ens),1,-1
        IF( mod(fne,sub_ens(i)) .eq. 0 ) THEN
           sub_ens_size = sub_ens(i)
           exit
        ENDIF
      ENDDO
      write(std_out,*)
      write(std_out,*) "               ", fne, " MEMBERS ARE GROUPED INTO ",fne/sub_ens_size," SETS OF ", sub_ens_size
      write(std_out,*)
    ELSE
      write(std_out,*) "COMPUTE_LETKF:  RCF == 0, NO ADAPTIVE RCF CALCALUTIONS USED"
      sub_ens_size = 0
    ENDIF


! Logic for inflation, set defaults, and initialize out_inflate since not all grid points are processed.


    !!! ------------- PRIOR INFLATION ------------- !!!
    
    out_inflate(:,:,:) = in_inflate(:,:,:) ! python code handles all set up now. 

    IF( prior_inflate .eq. 1 ) THEN
      write(std_out,*) 
      write(std_out,*) "COMPUTE_LETKF: PRIOR ADAPTIVE INFLATION IS ON"
      write(std_out,*) "               Min value of AI:  ",sqrt(minval(out_inflate))
      write(std_out,*) "               Max value of AI:  ",sqrt(maxval(out_inflate))
      WHERE( out_inflate > max_inflate ) out_inflate = max_inflate
      write(std_out,*) "               Max value of limited AI:  ",sqrt(maxval(out_inflate))
      write(std_out,*) 
    ENDIF


    IF( prior_inflate .eq. 2 ) THEN
      write(std_out,*) 
      write(std_out,*) "COMPUTE_LETKF: FIXED PRIOR INFLATION IS ON"
      write(std_out,*) "               Min value of AI:  ",sqrt(minval(out_inflate))
      write(std_out,*) "               Max value of AI:  ",sqrt(maxval(out_inflate))
      write(std_out,*) 
    ENDIF
    

    !!! ------------- POSTERIOR INFLATION ------------- !!!
    
    IF (post_inflate .eq. 1) THEN 
        inflate_RTPS = post_inflate_alpha 
        write(std_out,*) 
        write(std_out,*) "COMPUTE_LETKF: WH2010 RTPS INFLATION IS ON"
        write(std_out,*) "                 Inflation alpha is: ", inflate_RTPS 
        write(std_out,*)
    ENDIF


    IF (post_inflate .eq. 2) THEN 
        inflate_RTPS = post_inflate_alpha 
        write(std_out,*) 
        write(std_out,*) "COMPUTE_LETKF: ADAPTIVE WH2010 RTPS INFLATION IS ON"
        write(std_out,*) "                 Inflation alpha is starting at: ", inflate_RTPS  
        write(std_out,*)
    ENDIF


    IF (post_inflate .eq. 3) THEN 
        inflate_RTPP = post_inflate_alpha
        write(std_out,*) 
        write(std_out,*) "COMPUTE_LETKF: ADAPTIVE RELAXATION TO TO PRIOR PERTURBATION (RTPP) is ON"
        write(std_out,*) "                 Relaxtion alpha is: ", inflate_RTPP 
        write(std_out,*)
    ENDIF


    IF (post_inflate .eq. 4) THEN  ! i am not quite sure how it handles the adaptive alpha yet
        inflate_RTPP = post_inflate_alpha
        write(std_out,*) 
        write(std_out,*) "COMPUTE_LETKF: RELAXATION TO PRIOR PERTURBATION (RTPP) is ON"
        write(std_out,*) "                 Relaxtion alpha is starting at: ", inflate_RTPP  
        write(std_out,*)
    ENDIF


    !!! other settings !!!

    write(std_out,*) "COMPUTE_LETKF: POSITIVE DEFINITE SCHEME IS:  ", pos_def_scheme
    write(std_out,*) "COMPUTE_LETKF: POSITIVE DEFINITE FLOOR VALUE:  ", nu0
    write(std_out,*)

    CALL OMP_SET_NUM_THREADS(nthreads)
    CALL OMP_SET_DYNAMIC(.FALSE.)       ! Needed for some shared memory systems

    write(std_out,*) "COMPUTE_LETKF: MAXIMUM NUMBER OF THREADS AVAILABLE:  ", OMP_GET_MAX_THREADS()
    write(std_out,*) "COMPUTE_LETKF: NUMBER OF THREADS TO USE IS:          ", OMP_GET_NUM_THREADS()
    write(std_out,*) "COMPUTE_LETKF: INFLATION at (21,51,41) ", in_inflate(21,51,41)
    write(std_out,*)

!---------------->>>   MAIN COMPUTATIONAL LOOP FOR LETKF   <<<------------------------------------------------

    t_letkf = omp_get_wtime()

    DO i = 1,nx
      x0 = xc(i) - xoffset
      DO j = 1,ny
        y0 = yc(j) - yoffset

        IF( read_weights .eqv. .false. ) THEN
       
!$OMP PARALLEL DO DEFAULT(SHARED) PRIVATE(m,k,z0,t1,t0,nvalid,obindex,obwgt,trans,mean_wgt,new1,var,rcf_coeff) &
!$OMP REDUCTION( +: t_local ) REDUCTION( +: t_core ) REDUCTION( +: t_update) REDUCTION( +: gp_update_count ) &
!$OMP REDUCTION( +: total_valid_obs ) REDUCTION( +: rcf_mean )

        DO k = 1,nz
          z0 = zc(k) 
        
          IF( z0 .gt. zcutoff + rvert) THEN
            cycle
          ENDIF
          
          t0 = omp_get_wtime()

          CALL LOCALIZATION(fnobs, xob, yob, zob, tob, x0, y0, z0, tanalysis, rhoriz, rvert, rtime, &
                            cutoff, obindex, obwgt)
      
          t_local = t_local + omp_get_wtime() - t0

          nvalid = count(obindex .ne. -1)
        
          IF (nvalid > 0) THEN
          
            gp_update_count = gp_update_count + 1
            total_valid_obs = total_valid_obs + nvalid


            !-------------->>>   if not adaptive or no post inflation, call LETKF_CORE once and UPDATE for each state variable individually   <<<-------------------- 

            IF (post_inflate.eq.0 .or. post_inflate.eq.1 .or. post_inflate.eq.3) THEN 

              t0 = omp_get_wtime()              ! Compute transformation matrix
              CALL LETKF_CORE(fne, fnobs, nvalid, var, Hx, rdiag, obwgt, dep, obindex, in_inflate(k,j,i), &
                              trans, mean_wgt, out_inflate(k,j,i), 0, rcf_coeff)
                                        
              t_core = t_core + omp_get_wtime() - t0
              DO m = 1,nxyz3d
                var(:) = xyz3d(m,:,k,j,i)
                CALL UPDATE(var, trans, mean_wgt, out_inflate(k,j,i), post_inflate, posdef(m), ne, new1, fnobs, &
                              nvalid, 0, Hx, obindex) 

                xyz3d(m,:,k,j,i) = new1(:)
              ENDDO! m-index
            
            
            
            !-------------->>>   if adaptive, call LETKF_CORE and UPDATE for each state variable individually   <<<-------------------- 
            
            ELSEIF (post_inflate.eq.2) THEN

              t0 = omp_get_wtime()              ! Compute transformation matrix
              DO m = 1,nxyz3d
              
                var(:) = xyz3d(m,:,k,j,i)

               
                
                CALL LETKF_CORE(fne, fnobs, nvalid, var, Hx, rdiag, obwgt, dep, obindex, in_inflate(k,j,i), &
                                trans, mean_wgt, out_inflate(k,j,i), sub_ens_size, rcf_coeff)

                rcf_mean(m) = rcf_mean(m) + rcf_coeff(1)               
                t_core = t_core + omp_get_wtime() - t0

                 
                CALL UPDATE(var, trans, mean_wgt, out_inflate(k,j,i), post_inflate, posdef(m), ne, new1, fnobs, &
                            nvalid, 0, Hx, obindex)
                            
                xyz3d(m,:,k,j,i) = new1(:)
            
              ENDDO  ! m-index


              ELSEIF (post_inflate.eq.4) THEN

                  t0 = omp_get_wtime()              ! Compute transformation matrix
                  DO m = 1,nxyz3d
                  
                    var(:) = xyz3d(m,:,k,j,i)
    
                    CALL LETKF_CORE(fne, fnobs, nvalid, var, Hx, rdiag, obwgt, dep, obindex, in_inflate(k,j,i), &
                                    trans, mean_wgt, out_inflate(k,j,i), 0, rcf_coeff)
    
                                 
                    t_core = t_core + omp_get_wtime() - t0
    
                    rcf_coeff(1) = inflate_RTPP 
                     
                    CALL UPDATE(var, trans, mean_wgt, out_inflate(k,j,i), post_inflate, posdef(m), ne, new1, fnobs, &
                                nvalid, 0, Hx, obindex, rcf_coeff)
    
                    rcf_mean(m) = rcf_mean(m) + rcf_coeff(1) 
                                
                    xyz3d(m,:,k,j,i) = new1(:)
                
                  ENDDO  ! m-index
              

            ENDIF ! post_inflate flate 

        

            IF( save_weights ) THEN
              trans3D(:,:,k,j,i)  = trans(:,:)
              mean_wgt3D(:,k,j,i) = mean_wgt(:)
            ENDIF
              
            ENDIF      ! END NVALID >0

          ENDDO ! k-index

!$OMP END PARALLEL  DO

        ELSE   ! just use the weights read in....

!$OMP PARALLEL DO DEFAULT(SHARED) PRIVATE(m,k,z0,trans,mean_wgt,new1,var)

          DO k = 1,nz
            z0 = zc(k) 
        
            IF( z0 .gt. zcutoff + rvert) THEN
              cycle
            ENDIF
          
             trans(:,:) = trans3D(:,:,k,j,i)  
             mean_wgt(:) = mean_wgt3D(:,k,j,i) 

            DO m = 1,nxyz3d
  
              var(:) = xyz3d(m,:,k,j,i)

              CALL UPDATE(var, trans, mean_wgt, out_inflate(k,j,i), post_inflate, posdef(m), ne, new1, fnobs, &
                          nvalid, 0, Hx, obindex)

              xyz3d(m,:,k,j,i) = new1(:)

            ENDDO ! m - index

          ENDDO ! k-index

!$OMP END PARALLEL  DO

        ENDIF ! read_weights condition
          
        ENDDO  ! j-index
      ENDDO  ! i-index

    CALL OMP_SET_NUM_THREADS(1)

!------------------------------------------------------------------------------------------------------------- 

    write(std_out,*) 
    write(std_out,*) "COMPUTE_LETKF:  Fortran WALLCLOCK CPU FOR ALL  :  ", (omp_get_wtime() - t_letkf), " secs"
    write(std_out,*) "COMPUTE_LETKF:  Fortran WALLCLOCK CPU for CORE :  ", t_core, " secs"
    write(std_out,*) "COMPUTE_LETKF:  Fortran WALLCLOCK CPU for LOCAL:  ", t_local, " secs"
    write(std_out,*) "COMPUTE_LETKF:  Number of grid points updated is: ", gp_update_count
    write(std_out,*) "COMPUTE_LETKF:  Number of observations used is: ", total_valid_obs
    write(std_out,*) 


    IF( post_inflate .eq. 2) THEN   ! print out Mean Adaptive RTPS value for each state variable...
      rcf_mean(:) = rcf_mean(:) / float(gp_update_count)
      write(std_out,FMT='("COMPUTE_LETKF:  INITIAL RTPS VALUE:  ",g15.7," no inflat <- 0 (value) 1 -> full inflat")') inflate_RTPS
      DO m = 1,nxyz3d
        write(std_out,FMT='("COMPUTE_LETKF:  State Variable:  ",i2," MEAN RTPP Value: ",g15.7)') m, rcf_mean(m)
      ENDDO
    ENDIF
 
    IF( post_inflate .eq. 4 ) THEN   ! print out Mean Adaptive RTPS value for each state variable...
      rcf_mean(:) = rcf_mean(:) / float(gp_update_count)
      write(std_out,FMT='("COMPUTE_LETKF:  INITIAL RTPP VALUE:  ",g15.7," posterior <- 0 (value) 1 -> prior")') inflate_RTPP
      DO m = 1,nxyz3d
        write(std_out,FMT='("COMPUTE_LETKF:  State Variable:  ",i2," MEAN RTPP Value: ",g15.7)') m, rcf_mean(m)
      ENDDO
    ENDIF

! Deallocate local space for LETKF double precision variables

    deallocate(var)
    deallocate(new1)
    deallocate(trans)
    deallocate(mean_wgt)
    deallocate(obwgt)
    deallocate(obindex)


   CALL FLUSH(6)
    
  RETURN
  END SUBROUTINE COMPUTE_LETKF



!=============================================================================================================
  SUBROUTINE ALLOCATE_FSTATE(fnx,fny,fnz,fnxyz3d,fne)

    integer, intent(in) :: fnx, fny, fnz, fne, fnxyz3d
    
    IF( (fne .ne. ne .and. fne .ne. ne+1) .and. ne > 0 ) THEN
      write(std_err,*) "ALLOCATE_FSTATE:  Input ensemble size [NE] is not equal to current NE...FATAL ERROR!!"
      write(std_err,*) "ALLOCATE_FSTATE:  Input ensemble size:    ", fne
      write(std_err,*) "ALLOCATE_FSTATE:  Current ensemble size:  ", ne
      stop
    ELSE
      ne = fne
    ENDIF
    nx     = fnx
    ny     = fny
    nz     = fnz
    nxyz3d = fnxyz3d

    IF( allocated(posdef) ) THEN
      write(std_err,*) "ALLOCATE_ARRAY:  Error, positive already allocated, deallocating, then reallocating"
      deallocate(posdef)
    ENDIF
    allocate(posdef(nxyz3d))

    IF( allocated(var_inflation) ) THEN
      write(std_err,*) "ALLOCATE_ARRAY:  Error, var_inflation already allocated, deallocating, then reallocating"
      deallocate(var_inflation)
    ENDIF
    allocate(var_inflation(nxyz3d))

    IF( allocated(late) ) THEN
      write(std_err,*) "ALLOCATE_ARRAY:  Error, late already allocated, deallocating, then reallocating"
      deallocate(late)
    ENDIF
    allocate(late(ny+1))

    IF( allocated(lone) ) THEN
      write(std_err,*) "ALLOCATE_ARRAY:  Error, lone already allocated, deallocating, then reallocating"
      deallocate(lone)
    ENDIF
    allocate(lone(nx+1))

    IF( allocated(xe) ) THEN
      write(std_err,*) "ALLOCATE_ARRAY:  Error, xe already allocated, deallocating, then reallocating"
      deallocate(xe)
    ENDIF
    allocate(xe(nx+1))

    IF( allocated(ye) ) THEN
      write(std_err,*) "ALLOCATE_ARRAY:  Error, ye already allocated, deallocating, then reallocating"
      deallocate(ye)
    ENDIF
    allocate(ye(ny+1))

    IF( allocated(ze) ) THEN
      write(std_err,*) "ALLOCATE_ARRAY:  Error, ze already allocated, deallocating, then reallocating"
      deallocate(ze)
    ENDIF
    allocate(ze(nz))

    IF( allocated(xc) ) THEN
      write(std_err,*) "ALLOCATE_ARRAY:  Error, xc already allocated, deallocating, then reallocating"
      deallocate(xc)
    ENDIF
    allocate(xc(nx+1))

    IF( allocated(yc) ) THEN
      write(std_err,*) "ALLOCATE_ARRAY:  Error, yc already allocated, deallocating, then reallocating"
      deallocate(yc)
    ENDIF
    allocate(yc(ny+1))

    IF( allocated(zc) ) THEN
      write(std_err,*) "ALLOCATE_ARRAY:  Error, zc already allocated, deallocating, then reallocating"
      deallocate(zc)
    ENDIF
    allocate(zc(nz+1))

    IF( allocated(uinit) ) THEN
      write(std_err,*) "ALLOCATE_ARRAY:  Error, uinit already allocated, deallocating, then reallocating"
      deallocate(uinit)
    ENDIF
    allocate(uinit(ne,nz))

    IF( allocated(vinit) ) THEN
      write(std_err,*) "ALLOCATE_ARRAY:  Error, vinit already allocated, deallocating, then reallocating"
      deallocate(vinit)
    ENDIF
    allocate(vinit(ne,nz))

    IF( allocated(thinit) ) THEN
      write(std_err,*) "ALLOCATE_ARRAY:  Error, thinit already allocated, deallocating, then reallocating"
      deallocate(thinit)
    ENDIF
    allocate(thinit(ne,nz))

    IF( allocated(qvinit) ) THEN
      write(std_err,*) "ALLOCATE_ARRAY:  Error, qvinit already allocated, deallocating, then reallocating"
      deallocate(qvinit)
    ENDIF
    allocate(qvinit(ne,nz))

    IF( allocated(piinit) ) THEN
      write(std_err,*) "ALLOCATE_ARRAY:  Error, piinit already allocated, deallocating, then reallocating"
      deallocate(piinit)
    ENDIF
    allocate(piinit(ne,nz))

    IF( allocated(u) ) THEN
      write(std_err,*) "ALLOCATE_ARRAY:  Error, u already allocated, deallocating, then reallocating"
      deallocate(u)
    ENDIF
    allocate(u(ne,nz,ny,nx+1))
    
    IF( allocated(v) ) THEN
      write(std_err,*) "ALLOCATE_ARRAY:  Error, v already allocated, deallocating, then reallocating"
      deallocate(v)
    ENDIF
    allocate(v(ne,nz,ny+1,nx))
    
    IF( allocated(w) ) THEN
      write(std_err,*) "ALLOCATE_ARRAY:  Error, w already allocated, deallocating, then reallocating"
      deallocate(w)
    ENDIF
    allocate(w(ne,nz+1,ny,nx))
    
!   IF( allocated(xy2d) ) THEN
!     write(std_err,*) "ALLOCATE_ARRAY:  Error, xy2d already allocated, deallocating, then reallocating"
!     deallocate(xy2d)
!   ENDIF
!   allocate(xy2d(nxy2d,ne,ny,nx))

    IF( allocated(xyz3d) ) THEN
      write(std_err,*) "ALLOCATE_ARRAY:  Error, xyz3d already allocated, deallocating, then reallocating"
      deallocate(xyz3d)
    ENDIF
    allocate(xyz3d(nxyz3d,ne,nz,ny,nx))
    
  RETURN
  END SUBROUTINE ALLOCATE_FSTATE

!=============================================================================================================
  SUBROUTINE DEALLOCATE_FSTATE()

    IF( allocated(latc)     ) deallocate(latc)
    IF( allocated(late)     ) deallocate(late)
    IF( allocated(lonc)     ) deallocate(lonc)
    IF( allocated(lone)     ) deallocate(lone)
    IF( allocated(xc)       ) deallocate(xc)
    IF( allocated(xe)       ) deallocate(xe)
    IF( allocated(yc)       ) deallocate(yc)
    IF( allocated(ye)       ) deallocate(ye)
    IF( allocated(zc)       ) deallocate(zc)
    IF( allocated(ze)       ) deallocate(ze)
!   IF( allocated(xy2d)     ) deallocate(xy2d)
    IF( allocated(xyz3d)    ) deallocate(xyz3d)
    IF( allocated(posdef)   ) deallocate(posdef)
    
  RETURN
  END SUBROUTINE DEALLOCATE_FSTATE

!=============================================================================================================
END MODULE FSTATE


!=============================================================================================================   

SUBROUTINE LOCALIZATION(nobs, xob, yob, zob, tob, x, y, z, t, rhoriz, rvert, rtime, cutoff, obindex, obwgt)

! Passed variables
!-----------------------------------------------------------------

  IMPLICIT NONE

  integer,      intent(IN)    :: nobs
  integer,      intent(IN)    :: cutoff
  real(kind=8), intent(IN)    :: x, y, z, t
  real(kind=8), intent(IN)    :: xob(nobs), yob(nobs), zob(nobs), tob(nobs)
  real(kind=8), intent(IN)    :: rhoriz, rvert, rtime
  real(kind=8), intent(INOUT) :: obwgt(nobs)
  integer,      intent(INOUT) :: obindex(nobs)

! Local variables
!-----------------------------------------------------------------
  integer       :: n, nvalid
  real(kind=8)  :: distance
  real(kind=8)  :: wgt, twgt
  logical       :: valid(nobs)
  integer       :: vindex(nobs)
  
!---- Functions

  real(kind=8)  :: comp_cov_factor 
  real(kind=8), parameter :: half = 0.5

!  write(std_out,*) 'LOCALIZATION:  X_OB Max/Min:  ', maxval(xob), minval(xob), x
!  write(std_out,*) 'LOCALIZATION:  Y_OB Max/Min:  ', maxval(yob), minval(yob), y
!  write(std_out,*) 'LOCALIZATION:  Z_OB Max/Min:  ', maxval(zob), minval(zob), z


  IF ( rtime .gt. 0.0 ) THEN
  
!!!!$OMP PARALLEL DO DEFAULT(SHARED) PRIVATE(wgt, twgt)
  
    DO n = 1,nobs

    obindex(n) = -1
    valid(n)  = .false.
    wgt       = sqrt( ((zob(n)-z)/rvert)**2 + ((yob(n)-y)/rhoriz)**2 + ((xob(n)-x)/rhoriz)**2 ) 
    twgt      = sqrt( (tob(n)/rtime)**2 )
    vindex(n) = n
    obwgt(n)  = 0.0d0
    IF( wgt .lt. 1.0 .and. twgt .lt. 1.0 ) THEN
      valid(n) = .true.
      obwgt(n) = comp_cov_factor(wgt,half)*comp_cov_factor(twgt,half)
    ENDIF

  ENDDO

!!!$OMP END PARALLEL DO

  ELSE

!!!$OMP PARALLEL DO DEFAULT(SHARED) PRIVATE(wgt)

    DO n = 1,nobs
  
      obindex(n) = -1
      valid(n)  = .false.
      wgt       = sqrt( ((zob(n)-z)/rvert)**2 + ((yob(n)-y)/rhoriz)**2 + ((xob(n)-x)/rhoriz)**2 )
      vindex(n) = n
      obwgt(n)  = 0.0d0
      IF( wgt .lt. 1.0 ) THEN
        valid(n) = .true.
        obwgt(n) = comp_cov_factor(wgt,half)
      ENDIF

    ENDDO

!!!$OMP END PARALLEL DO
    
  ENDIF
  
! Gather scatter code for compressing indices to front of oindex array

  nvalid = count( valid )
  obindex(1:nvalid) = pack(vindex, valid)
  
RETURN
END SUBROUTINE LOCALIZATION

!=============================================================================================================   

SUBROUTINE LOCALIZATION1D(nobs, xob, yob, zob, tob, x, y, z, t, rhoriz, rvert, rtime, cutoff, obindex, obwgt)

! Passed variables
!-----------------------------------------------------------------

  IMPLICIT NONE

  integer,      intent(IN)    :: nobs
  integer,      intent(IN)    :: cutoff
  real(kind=8), intent(IN)    :: x, y, z, t
  real(kind=8), intent(IN)    :: xob(nobs), yob(nobs), zob(nobs), tob(nobs)
  real(kind=8), intent(IN)    :: rhoriz, rvert, rtime
  real(kind=8), intent(INOUT) :: obwgt(nobs)
  integer,      intent(INOUT) :: obindex(nobs)

! Local variables
!-----------------------------------------------------------------
  integer       :: n, nvalid, n0, n1
  real(kind=8)  :: distance
  real(kind=8)  :: wgt, twgt
  logical       :: valid(nobs)
  integer       :: vindex(nobs)
  integer find_index8
  
!---- Functions

  real(kind=8)  :: comp_cov_factor 
  real(kind=8), parameter :: half = 0.5

!  write(std_out,*) 'LOCALIZATION:  X_OB Max/Min:  ', maxval(xob), minval(xob), x
!  write(std_out,*) 'LOCALIZATION:  Y_OB Max/Min:  ', maxval(yob), minval(yob), y
!  write(std_out,*) 'LOCALIZATION:  Z_OB Max/Min:  ', maxval(zob), minval(zob), z

  n0 = 0
  n1 = 0
  n0 = find_index8(x-rhoriz, xob, nobs)
  n1 = find_index8(x+rhoriz, xob, nobs)
! IF ((n1-n0) > 0) THEN
!   n0 = find_index(y+rhoriz, yob(nx0:nx1), nx1-nx0)
!   ny1 = find_index(y-rhoriz, yob(nx0:nx1), nx1-nx0)
! ELSE
!   ny0 = 0
!   ny1 = 0
! ENDIF
! IF ((ny1-ny0) > 0) THEN
!   nz0 = find_index(z+rvert,  zob(ny0:ny1), ny1-ny0)
!   nz1 = find_index(z-rvert,  zob(ny0:ny1), ny1-ny0)
! ELSE
!  nz0 = 0
!  nz1 = 0
! ENDIF

  IF ( rtime .gt. 0.0 ) THEN
  
!!!!$OMP PARALLEL DO DEFAULT(SHARED) PRIVATE(wgt, twgt)
  
   DO n = 1,nobs

    obindex(n) = -1
    valid(n)  = .false.
    wgt       = sqrt( ((zob(n)-z)/rvert)**2 + ((yob(n)-y)/rhoriz)**2 + ((xob(n)-x)/rhoriz)**2 ) 
    twgt      = sqrt( (tob(n)/rtime)**2 )
    vindex(n) = n
    obwgt(n)  = 0.0d0

    IF( wgt .lt. 1.0 .and. twgt .lt. 1.0 ) THEN
      valid(n) = .true.
      obwgt(n) = comp_cov_factor(wgt,half)*comp_cov_factor(twgt,half)
    ENDIF

   ENDDO

!!!$OMP END PARALLEL DO

  ELSE

!!!$OMP PARALLEL DO DEFAULT(SHARED) PRIVATE(wgt)

    DO n = 1,nobs
  
      obindex(n) = -1
      valid(n)  = .false.
      wgt       = sqrt( ((zob(n)-z)/rvert)**2 + ((yob(n)-y)/rhoriz)**2 + ((xob(n)-x)/rhoriz)**2 )
      vindex(n) = n
      obwgt(n)  = 0.0d0
      IF( wgt .lt. 1.0 ) THEN
        valid(n) = .true.
        obwgt(n) = comp_cov_factor(wgt,half)
      ENDIF

    ENDDO

!!!$OMP END PARALLEL DO
    
  ENDIF
  
! Gather scatter code for compressing indices to front of oindex array

  nvalid = count( valid )
  obindex(1:nvalid) = pack(vindex, valid)

  IF ((n1-n0) > 0) THEN
    write(8,FMT='(a,3(f8.1,2x))') 'grid point coordinates:  ', x, y, z
    write(8,FMT='(a,3(f8.1,2x))') 'min obs point coordinates:  ', xob(n0), yob(n0), zob(n0)
    write(8,FMT='(a,3(f8.1,2x))') 'max obs point coordinates:  ', xob(n1), yob(n1), zob(n1)
    write(8,*) 'nvalid / nvalid2:  ', nvalid, n1-n0
  ENDIF
  
RETURN
END SUBROUTINE LOCALIZATION1D

!=============================================================================================================   
SUBROUTINE UPDATE(var, trans, wa, inflate, post_inflate, pos_def, ne, new1, & 
                  nobs, nvalid_obs, sub_ens_size, hdxb, obIndex, adapt_rtpp)

  USE INFLATE_PARAMS

! Passed variables
!-------------------------------------------------------------------------------------

  integer,         intent(IN)  :: pos_def
  integer,         intent(IN)  :: post_inflate
  integer,         intent(IN)  :: ne
  real(kind=4),    intent(IN)  :: var(ne)                   ! state vector at a point + mean
  real(kind=8),    intent(IN)  :: trans(ne-1,ne-1)
  real(kind=8),    intent(IN)  :: wa(ne-1)                  ! weights for mean
  real(kind=8),    intent(IN)  :: inflate
  real(kind=4),    intent(OUT) :: new1(ne)
  integer(kind=4), intent(IN)  :: nobs                      ! No. of observations
  integer(kind=4), intent(IN)  :: nvalid_obs                ! No. of valid bservations
  real(kind=8),    intent(IN)  :: hdxb(nobs,ne-1)           ! The observaton priors
  integer(kind=4), intent(IN)  :: obIndex(nobs)             ! Index (mask) for valid observations
  integer(kind=4), intent(IN)  :: sub_ens_size              ! The number of sub-ensembles for heirarctical filter

  real(kind=8),    intent(INOUT), optional :: adapt_rtpp(1) ! Input:  background value to blend width...
                                                            ! Output: total RTPP value used for update

! Local variables
!-------------------------------------------------------------------------------------

  real(kind=4)    :: pvar(ne-1), pvarsq(ne-1), var2(ne), vartmp(ne-1)
  real(kind=4)    :: sigmaB, sigmaA
  real(kind=8)    :: inflate1, inflate2, ai_fac
  integer(kind=4) :: n
  real(kind=8)    :: HxfL(ne-1)
  real(kind=8)    :: rcf_mean, rcf0
  real(kind=4)    :: F_RCF, F_CORR
  external        :: F_RCF, F_CORR

  var2(:) = var(:)

! IF pos_def & pos_def_scheme = 2 --> use Ooyma (2001) transformation

  IF( pos_def .eq. 1 .and. pos_def_scheme .eq. 2 ) THEN
    var2(:) = 0.5*( (var2(:) + nu0) - nu0**2/(var2(:) + nu0) )
  ELSEIF( pos_def .eq. 1 .and. pos_def_scheme .eq. 3 ) THEN
    var2(:) = log(max(var2,nu0))
  ENDIF

  pvar = var2(1:ne-1) - var2(ne) 

! Update mean

  new1(ne) = var2(ne) + dot_product(pvar, wa)

! Update perturbations

  new1(1:ne-1) = matmul(pvar, trans)

! relaxation to prior spread (RTPS) WH2010 

  IF (post_inflate .eq. 1) THEN ! RTPS with fixed alpha

    ! Compute background (prior) and analysis (posterior) variances
    sigmaB = sqrt( sum(pvar*pvar) / float(ne-2) )
    sigmaA = sqrt( sum(new1(1:ne-1)*new1(1:ne-1)) / float(ne-2) )
    
    inflate2     = 1.0 + inflate_RTPS*((sigmaB-sigmaA)/(eps+sigmaA))
    new1(1:ne-1) = new1(1:ne-1) * inflate2

  ENDIF
  

  IF (post_inflate .eq. 2) THEN ! RTPS with adapative alpha
  
   ! Compute background (prior) and analysis (posterior) variances
    sigmaB = sqrt( sum(pvar*pvar) / float(ne-2) )
    sigmaA = sqrt( sum(new1(1:ne-1)*new1(1:ne-1)) / float(ne-2) )
    
    rcf_mean = 0.0d0
    vartmp   = var(1:ne-1)
    DO m = 1,nvalid_obs
      HxfL(:)  = hdxb(obIndex(m),:)
      rcf0     = F_RCF(vartmp, HxfL, ne-1, sub_ens_size)
      rcf_mean = rcf_mean + rcp0
    ENDDO
    
    rcf_mean = rcf_mean / float(nvalid_obs)
    adapt_rtpp(1) = (1.0 - inflate_RTPS) * rcf_mean + inflate_RTPS
    inflate2      = 1.0 + adapt_rtpp(1)*((sigmaB-sigmaA)/(eps+sigmaA))
    new1(1:ne-1)  = new1(1:ne-1) * inflate2
    
  ENDIF

    

! Relaxation to the prior perturbation (RTPP) from Zhang et al (2004) 
! Note: inflate_RTPP/adapt_rtpp = 1.0, the prior perturbations replace the new perturbations


  IF (post_inflate .eq. 3) THEN !RTPP with fixed alpha 

   ! write(6,*) 
   ! write(6,*) "COMPUTE_LETKF: TESTING THAT RTPP IS UPDATING"
   ! write(6,*) "                 Relaxtion alpha is: ", inflate_RTPP 
   ! write(6,*)
    
    new1(1:ne-1) = pvar(1:ne-1) * inflate_RTPP + (1.0 - inflate_RTPP) * new1(1:ne-1)
  ENDIF
  

!  IF (post_inflate.eq. 4) THEN !RTPP with adaptive alpha 
!
!    rcf_mean = 0.0d0
!    vartmp   = var(1:ne-1)
!    DO m = 1,nvalid_obs
!      HxfL(:)  = hdxb(obIndex(m),:)
!      rcf0     = F_RCF(vartmp, HxfL, ne-1, sub_ens_size)
!      rcf_mean = rcf_mean + rcf0
!    ENDDO
!    rcf_mean = rcf_mean / float(nvalid_obs)
!
!    adapt_rtpp(1) = adapt_rtpp(1) - (1.0 - adapt_rtpp(1)) * rcf_mean 
!    new1(1:ne-1)  = pvar(1:ne-1) * adapt_rtpp(1) + (1.0 - adapt_rtpp(1)) * new1(1:ne-1)
!
!  ENDIF


    IF (post_inflate.eq. 4) THEN !RTPP with adaptive alpha 

    ! this scales so that lower values of inflation ( less than 1) are mapped down to 0.3 (more analysis)
    ! and larger values of inflation (greater than 1) are mapped up to 0.9 (more background)
    adapt_rtpp(1) = (max( min(inflate, 2.0), 1.0) - 1.0) * (RTPP_top - RTPP_base) + RTPP_base

    ! to have larger values of inflation be mapped to lower relation coefficients (more analysis), use this line instead:
    !adapt_rtpp(1) = -1*(max( min(inflate, 2.0), 1.0) - 2.0) * (RTPP_top - RTPP_base) + RTPP_base
    
    new1(1:ne-1)  = pvar(1:ne-1) * adapt_rtpp(1) + (1.0 - adapt_rtpp(1)) * new1(1:ne-1)


  ENDIF
  

! Add mean back in and its the PRIOR MEAN according to Hunt et al (2007; eq. 25)

  new1(1:ne-1) = var2(ne) + new1(1:ne-1) 

! If pos_def variable, make sure it > 0 ......

  IF( pos_def .eq. 1 .and. pos_def_scheme .eq. 2 ) THEN
    DO n = 1,ne
      IF( new1(n) .gt. 0.0 ) THEN
        new1(n) = sqrt(new1(n)**2 + nu0**2) + new1(n) - nu0
      ELSE
        new1(n) = 0.0
      ENDIF
    ENDDO
  ELSEIF( pos_def .eq. 1 .and. pos_def_scheme .eq. 3 ) THEN
    new1 = exp(new1)
  ELSEIF( pos_def .eq. 1 .and. pos_def_scheme .eq. 1 ) THEN
    new1 = max(new1, 0.)
  ENDIF

RETURN
END SUBROUTINE UPDATE


!=============================================================================================================   
FUNCTION COMP_COV_FACTOR(z_in, c)
!*****************************************************************************
!
!                ==>  FUNCTION COMP_COV_FACTOR(z_in, c)
!
!*****************************************************************************
! Function that calculates compactly supported correlation fn from
! Gaspari and Cohn (QJRMS 1999; their eqn 4.10).  Based on original
! code from J. Anderson.
!
! Let r = z_in/c. Then
!    cor(r) =   0,     r > 2c
!               r^5/12 -r^4/2 +(5/8)r^3 +(5/3)r^2 -5r +4 -(2/3)r^-1 ,
!                      c < r < 2c
!               -r^5/4 +r^4/2 +(5/8)r^3 -(5/3)r^2 +1,
!                      r < c
!
! INPUTS:  z_in = radius (in 3D)
!             c = 1/2 cutoff radius; correlation = 0 for z_in > 2c.
!
!*****************************************************************************

  implicit none

  real(kind=8) :: comp_cov_factor
  real(kind=8), intent(in) :: z_in, c
  real(kind=8) :: z, r

  z = dabs(z_in)
  r = z / c

  IF (z >= 2*c) THEN

   comp_cov_factor = 0.

  ELSE IF(z >= c .and. z < 2*c) THEN

   comp_cov_factor = ( ( ( ( r/12.  -0.5 )*r  +0.625 )*r +5./3. )*r  -5. )*r + 4. - 2./(3.*r)

  ELSE

   comp_cov_factor = ( ( ( -0.25*r +0.5 )*r +0.625 )*r  -5./3. )*r**2 + 1.

  ENDIF

 RETURN
 END


!###########################################################################
!
!     ##################################################################
!     ######                                                      ######
!     ######             INTEGER FUNCTION FIND_INDEX              ######
!     ######                                                      ######
!     ##################################################################
!
!     PURPOSE:
!
!     This function returns the array index (here, the value returned by
!     find_index is designated as i) such that x is between xa(i) and xa(i+1).
!     If x is less than xa(1), then i=0 is returned.  If x is greater than
!     xa(n), then i=n is returned.  It is assumed that the values of
!     xa increase monotonically with increasing i.
!
!############################################################################
!
!     Author:  David Dowell (based on "locate" algorithm in Numerical Recipes)
!
!     Creation Date:  17 November 2004
!
!############################################################################

INTEGER FUNCTION FIND_INDEX8(x, xa, n)

  implicit none

  integer n                          ! array size
  real(kind=8) xa(n)                 ! array of locations
  real(kind=8) x                     ! location of interest
  integer il, im, iu                 ! lower and upper limits, and midpoint

  il = 0
  iu = n+1

  IF ( x .gt. xa(n) ) THEN
    il = 0
  ELSEIF ( x .lt. xa(1) ) THEN
    il = 0
  ELSE

10  IF ((iu-il).gt.1) THEN
      im=(il+iu)/2
      IF( x.ge.xa(im) ) THEN
        il=im
      ELSE
        iu=im
     ENDIF
     go to 10
    ENDIF

  ENDIF

  find_index8 = il

RETURN
END

!###########################################################################
!
!     ##################################################################
!     ######                                                      ######
!     ######             INTEGER FUNCTION FIND_INDEX              ######
!     ######                                                      ######
!     ##################################################################
!
!     PURPOSE:
!
!     This function returns the array index (here, the value returned by
!     find_index is designated as i) such that x is between xa(i) and xa(i+1).
!     If x is less than xa(1), then i=0 is returned.  If x is greater than
!     xa(n), then i=n is returned.  It is assumed that the values of
!     xa increase monotonically with increasing i.
!
!############################################################################
!
!     Author:  David Dowell (based on "locate" algorithm in Numerical Recipes)
!
!     Creation Date:  17 November 2004
!
!############################################################################

INTEGER FUNCTION FIND_INDEX84(x, xa, n)

  implicit none

  integer n                          ! array size
  real(kind=4) xa(n)                 ! array of locations
  real(kind=8) x                     ! location of interest
  integer il, im, iu                 ! lower and upper limits, and midpoint

  il = 0
  iu = n+1

  IF ( x .gt. xa(n) ) THEN
    il = 0
  ELSEIF ( x .lt. xa(1) ) THEN
    il = 0
  ELSE

10  IF ((iu-il).gt.1) THEN
      im=(il+iu)/2
      IF( x.ge.xa(im) ) THEN
        il=im
      ELSE
        iu=im
     ENDIF
     go to 10
    ENDIF

  ENDIF

  find_index84 = il

RETURN
END
!###########################################################################
!
!     ##################################################################
!     ######                                                      ######
!     ######             INTEGER FUNCTION FIND_INDEX              ######
!     ######                                                      ######
!     ##################################################################
!
!     PURPOSE:
!
!     This function returns the array index (here, the value returned by
!     find_index is designated as i) such that x is between xa(i) and xa(i+1).
!     If x is less than xa(1), then i=0 is returned.  If x is greater than
!     xa(n), then i=n is returned.  It is assumed that the values of
!     xa increase monotonically with increasing i.
!
!############################################################################
!
!     Author:  David Dowell (based on "locate" algorithm in Numerical Recipes)
!
!     Creation Date:  17 November 2004
!
!############################################################################

INTEGER FUNCTION FIND_INDEX4(x, xa, n)

  implicit none

  integer n                          ! array size
  real(kind=4) xa(n)                 ! array of locations
  real(kind=4) x                     ! location of interest
  integer il, im, iu                 ! lower and upper limits, and midpoint

  il = 0
  iu = n+1

  IF ( x .gt. xa(n) ) THEN
    il = 0
  ELSEIF ( x .lt. xa(1) ) THEN
    il = 0
  ELSE

10  IF ((iu-il).gt.1) THEN
      im=(il+iu)/2
      IF( x.ge.xa(im) ) THEN
        il=im
      ELSE
        iu=im
     ENDIF
     go to 10
    ENDIF

  ENDIF

  find_index4 = il

RETURN
END

!======================================================================================================'
!
! Computed via Anderson (2007) Physica D
!
! Formulas from http://mathworld.wolfram.com/LeastSquaresFitting.html
!
!======================================================================================================'

REAL FUNCTION F_RCF(var, Hx, ne, me)

  implicit none
  
  integer(kind=4) ne, me  ! ne is number of obs, me is size of sub ensemble (referred to as hf in common_letkf.f90)
  real(kind=4) :: var(ne)
  real(kind=8) :: Hx(ne)
  
  real(kind=8) :: beta(ne/me), syy, sxy, vmean, Hxmean
  real(kind=8), parameter :: eps = 1.0e-15

  integer       :: n, m, ndm, nstart, nend
  integer, save :: error_flag = 0

  ndm = ne / me
  
! write(6,*) 'INSIDE F_RCF:  NE= ',ne, '  ME = ', me, ' NDM = ', ndm

  IF( mod(ne,me) .ne. 0 .and. error_flag < 10 ) THEN
    error_flag = error_flag + 1
    write(6,*) 'FUNCTION RCF:  ERROR ERROR ERROR!!!!'
    write(6,*) 'FUNCTION RCF:  MOD(# of ensemble members, # of sub-ensembles) != 0'
    write(6,*) 'FUNCTION RCF:  Returning RCF of 1.0'
    F_RCF = 1.0
    RETURN
  ENDIF
  
  DO m = 1,ndm
   nstart  = 1 + (m-1)*me 
   nend    =      (m) *me
   vmean   = SUM(var(nstart:nend))/float(me)
   Hxmean  = SUM(Hx(nstart:nend))/float(me)
   syy     = SUM(Hx(nstart:nend)**2) - me*Hxmean*Hxmean
   sxy     = SUM(var(nstart:nend)*Hx(nstart:nend)) - me*vmean*Hxmean
   IF( abs(syy) < eps ) THEN 
     beta(m) = 0.0   
   ELSE
     beta(m) = sxy / (syy + eps)   
   ENDIF
!  write(6,*) 'INSIDE F_RCF: ', m, nstart, nend
!  write(6,*) 'INSIDE F_RCF:  STATE MEAN = ',vmean, '  Hxmean = ', Hxmean
!  write(6,*) 'INSIDE F_RCF:  SYY= ',syy, '  SXY = ', sxy
!  write(6,*) 'INSIDE F_RCF:  BETA= ',beta(m)
  ENDDO
  
  F_RCF = max( ((SUM(beta(:))**2 / SUM(beta(:)**2)) - 1.0d0) / float(me - 1), 0.0d0)

! IF sample is small F_RCF can get > 1...bad things

  F_RCF = min(F_RCF, 1.0d0)
  
! IF( F_RCF > 0.1 ) write(6,*) 'F_RCF:  RCF= ',F_RCF

RETURN
END FUNCTION F_RCF

!======================================================================================================'
!
! Compute sample correlation function
!
! Formulas from http://mathworld.wolfram.com/LeastSquaresFitting.html
!
!======================================================================================================'

REAL FUNCTION F_CORR(var, Hx, ne)

  implicit none

  integer(kind=4) ne
  real(kind=4) :: var(ne)
  real(kind=8) :: Hx(ne)

  integer(kind=4) n
  real(kind=8) :: sx, sy, sxy, vmean, Hxmean
  real(kind=8), parameter :: eps = 1.0e-5

  integer, save :: error_flag = 0

! write(6,*) 'INSIDE F_CORR:  NE= ',ne

  vmean  = SUM(var) / float(ne)
  Hxmean = SUM(Hx) / float(ne)

  IF( abs(nint(100.0*Hxmean)) .lt. 0.001 ) THEN
    F_CORR = 1.0
    RETURN
  ENDIF 

  sx  = 0.0d0
  sy  = 0.0d0
  sxy = 0.0d0

  DO n = 1,ne
   sx  = sx  + ((var(n)-vmean)*(var(n)-vmean))
   sy  = sy  + ((Hx(n)-Hxmean)*(Hx(n)-Hxmean)) 
   sxy = sxy + ((var(n)-vmean)*(Hx(n)-Hxmean))
  ENDDO

  sx  = SQRT(sx / float(ne-1))
  sy  = SQRT(sy / float(ne-1))
  sxy = sxy / float(ne-1)
   
  F_CORR = ( sxy / (eps+sx*sy) ) / float(ne-1)

! write(6,*) 'INSIDE F_CORR: ', ne
! write(6,*) 'INSIDE F_CORR:  VAR MEAN = ',vmean, '  Hxmean = ', Hxmean
! write(6,*) 'INSIDE F_CORR:  SX = ',sx, 'SY = ', sy, '  SXY = ', sxy
! write(6,*) 'INSIDE F_CORR:  CORR = ', F_CORR

RETURN
END FUNCTION F_CORR

!======================================================================================================'
!
! Add Bubbles
!
! 
!
!======================================================================================================'
SUBROUTINE ADDBUBBLES_BOX(pert, rbubh, rbubv, nb, xloc, yloc, zloc, xc, yc, zc, &
                          xbmin, xbmax, ybmin, ybmax, classic_bubble, nx, ny, nz)
                   
  implicit none

! Passed in variables

  real(kind=4), INTENT(OUT) :: pert(nz,ny,nx)  ! 3D bubbles passed back to calling routine
      
  integer,      INTENT(IN)  :: nx, ny, nz, nb  ! grid dimensions, number of bubbles
  integer,      INTENT(IN)  :: classic_bubble  ! 1/0: cosine or r**2 weighting for bubble 
  real(kind=8), INTENT(IN)  :: xloc(nb)        ! coords. for nb bubbles relative to SW corner of domain
  real(kind=8), INTENT(IN)  :: yloc(nb)        ! coords. for nb bubbles relative to SW corner of domain
  real(kind=8), INTENT(IN)  :: zloc(nb)        ! coords. for nb bubbles relative to SW corner of domain      
  real(kind=8), INTENT(IN)  :: xbmin, ybmin    ! coords. of SW corner of domain
  real(kind=8), INTENT(IN)  :: xbmax, ybmax    ! coords. of NE corner of box
  real(kind=4), INTENT(IN)  :: xc(nx)          ! coordinates corresponding to grid indices
  real(kind=4), INTENT(IN)  :: yc(ny)          ! coordinates corresponding to grid indices
  real(kind=4), INTENT(IN)  :: zc(nz)        ! coordinates corresponding to grid indices

! Local variables

  integer i, i1, i2, j, j1, j2, k, k1, k2       ! loop variables
  integer n                                     ! number of blobs
  real dh, dv, wgt, beta                        ! weights
  real rbubh                                    ! horizontal radius (m) of blobs
  real rbubv                                    ! vertical radius (m) of blobs
  real(kind=8) x, y, z                          ! location of blob (m)
  real(kind=8), parameter :: pii = 4.0 * atan(1.0_8)
  integer, external :: find_index84

  logical, parameter :: debug = .false.

  pert(:,:,:) = 0.0

! Just do the calculations within the initial bubble box

  i1 = max(1,    find_index84(xbmin, xc, nx))     
  i2 = min(nx, 1+find_index84(xbmax, xc, nx))
  j1 = max(1,    find_index84(ybmin, yc, ny))     
  j2 = min(ny, 1+find_index84(ybmax, yc, ny))

  IF( debug) THEN
    print *, "FORTRAN ADDBUB DIMS:   ", nx, ny, nz, nb
    print *, "FORTRAN ADDBUB BUBBLE: ", classic_bubble
    print *, "FORTRAN ADDBUB SHAPE:  ", rbubh, rbubv
    print *, "FORTRAN ADDBUB X-LOCS: ", xloc
    print *, "FORTRAN ADDBUB Y-LOCS: ", yloc
    print *, "FORTRAN ADDBUB Z-LOCS: ", zloc
    print *, "FORTRAN ADDBUB X-BOX:  ", xbmin, xbmax
    print *, "FORTRAN ADDBUB Y-BOX:  ", ybmin, ybmax
    print *, "            SW CORNER: ", i1, j1
    print *, "            NE CORNER: ", i2, j2
  ENDIF
  
  DO n = 1,nb

    x = xloc(n)
    y = yloc(n)
    z = zloc(n)
                                                   
    k1 = max(1,    find_index84(z-rbubv, zc, nz))     
    k2 = min(nz, 1+find_index84(z+rbubv, zc, nz))

    IF( classic_bubble .eq. 1 ) THEN
    
      DO i = i1,i2       
        DO j = j1,j2  
          DO k = k1,k2  

            beta=sqrt(                           &
                      ((xc(i)-x)/rbubh)**2       &
                     +((yc(j)-y)/rbubh)**2       &
                     +((zc(k)-z)/rbubv)**2)
                     
            IF( beta .lt. 1.0) THEN
              pert(k,j,i) = (cos(0.5*pii*beta)**2)
            ENDIF
            
          ENDDO
        ENDDO
      ENDDO

    ELSE
     
      DO i = i1,i2       
        DO j = j1,j2  
          DO k = k1,k2  

            dh = (xc(i)-x)**2 + (yc(j)-y)**2
            dv = (zc(k)-z)**2                                    
            wgt = (1.0 - dh/rbubh**2 - dh/rbubh**2 - dv/rbubv**2) &
                / (1.0 + dh/rbubh**2 + dh/rbubh**2 + dv/rbubv**2)
                
            IF( wgt .gt. 0.0 ) THEN               
              pert(k,j,i) = pert(k,j,i) + wgt
            ENDIF
            
          ENDDO
       ENDDO
      ENDDO
       
    ENDIF
    
  ENDDO

RETURN
END

!======================================================================================================'
!
! Caya smooth perturbations....starting from an input array that has non-zero random noise
!      having a specifed standard deviation, generate smooth perturbations.
!
!
!  The technique is based on Caya et al. 2005, Monthly Weather Review, 3081-3094.
!
!======================================================================================================'
 SUBROUTINE ADD_SMOOTH_PERTS(pert, sd, lh, lv, xc, yc, zc, nx, ny, nz)

  implicit none
  
 ! Passed in variables

  real(kind=4), INTENT(OUT) :: pert(nz,ny,nx)             ! 3D bubbles passed back to calling routine
  real(kind=4), INTENT(IN)  :: sd(nz,ny,nx)               ! 3D array of random noise passed in based on some criteria
     
  integer,      INTENT(IN)  :: nx, ny, nz                 ! grid dimensions
  real(kind=4), INTENT(IN)  :: xc(nx)                     ! coordinates corresponding to grid indices
  real(kind=4), INTENT(IN)  :: yc(ny)                     ! coordinates corresponding to grid indices
  real(kind=4), INTENT(IN)  :: zc(nz)                     ! coordinates corresponding to grid indices
  real(kind=4), INTENT(IN)  :: lh, lv                     ! horiz. and vertical length scales of smoothing
 
 !---- local variables

  real, allocatable :: r(:,:,:)                           ! local storage for scaled or unscale noise

  integer i, i0, j, j0, k, k0                             ! grid indices
  real rlh, rlv                                           ! reciprocals of lh and lv
  real hdiff,vdiff                                        ! half-width of smoothing distances

  integer, external :: find_index4

  integer, allocatable, dimension(:,:) :: ii, jj, kk

  real    vol                                              ! grid volume of a given point
  real, parameter :: ref_vol= (1000.*1000.*500.)           ! reference grid volume
  logical, parameter :: normalize_perts_2_grid = .false.   ! whether to turn this on or off

 !---- code...
 
   rlh = 1.0 / lh
   rlv = 1.0 / lv

   hdiff = lh
   vdiff = lv

!  print *, hdiff, vdiff
!  print *, maxval(sd), minval(sd)

   allocate( r(nz,ny,nx) )
   
   allocate( ii(nx,2) )
   allocate( jj(ny,2) )
   allocate( kk(nz,2) )
   
   pert(:,:,:) = 0.0

! 12/5/08 ERM: Normalize to a 1km x 1km x 0.5 km grid volume
! This is needed because the perturbation amplitudes become
! function of the number of grid points summed - which is
! a function of grid resolution and the "lh" and "lv" specified
! filtering scales. (LJW)

   r(:,:,:) = sd(:,:,:)

   IF( normalize_perts_2_grid ) THEN
     DO k = 2,nz-1
       DO j = 2,ny-1
         DO i = 2,nx-1
           vol = 0.125 * (xc(i+1) - xc(i-1))*(yc(j+1) - yc(j-1))*(zc(k+1) - zc(k-1))
           r(i,j,k) = sd(i,j,k) * vol / ref_vol
         ENDDO
       ENDDO
     ENDDO
   ENDIF
   
   DO k = 1,nz
     kk(k,1) = max(1,    find_index4(zc(k)-vdiff, zc, nz))
     kk(k,2) = min(nz,   find_index4(zc(k)+vdiff, zc, nz))
   ENDDO

   DO j = 1,ny
     jj(j,1) = max(1,    find_index4(yc(j)-hdiff, yc, ny))
     jj(j,2) = min(ny, 1+find_index4(yc(j)+hdiff, yc, ny))
   ENDDO
   
   DO i = 1,nx
     ii(i,1) = max(1,    find_index4(xc(i)-hdiff, xc, nx))
     ii(i,2) = min(nx, 1+find_index4(xc(i)+hdiff, xc, nx))
   ENDDO
   
! Smooth the perturbations with an inverse exponential function
      
   DO i0 = 1,nx
     DO j0 = 1,ny
       DO k0 = 1,nz  
         IF( r(k0,j0,i0) .ne. 0.0 ) THEN

!!!!!!$omp parallel do default(shared), private(i,j,k)

             DO i = ii(i0,1), ii(i0,2)              
               DO j = jj(j0,1), jj(j0,2)
                 DO k = kk(k0,1),kk(k0,2)
                   pert(k,j,i) = pert(k,j,i)                            &
                             + r(k0,j0,i0)*exp( -abs(xc(i0)-xc(i))*rlh  &
                                                -abs(yc(j0)-yc(j))*rlh  &
                                                -abs(zc(k0)-zc(k))*rlv )
               ENDDO
             ENDDO
           ENDDO

         ENDIF

       ENDDO
     ENDDO
   ENDDO

  deallocate( r )
  deallocate( ii ) 
  deallocate( jj )  
  deallocate( kk )
      
 RETURN
 END
 
!======================================================================================================'
!
! Routine to map raw dbz obs to model grid for additive noise calcs.  Implemention
! uses the cKDTree algorithm in python to find the indices for each ob that is on the grid.
!
! Example code in python to create fields that are needed.
!=======================================================================================================
!# Begin python code
!
!import numpy, scipy.spatial
!import time
!
!# set up test grid
!
!x1d = numpy.arange(500) / 500.
!y1d = numpy.arange(600) / 600.
!z1d = numpy.arange(60)  / 60.
!
!y_array, z_array, x_array = numpy.meshgrid(y1d, z1d, x1d)
!combined_xyz_arrays = numpy.dstack([z_array.ravel(),y_array.ravel(),x_array.ravel()])[0]
!print 'XYZ ARRAY SHAPE', combined_xyz_arrays.shape
!
!obs = numpy.random.random(30).reshape(3,10)
!print 'Obs Shape:', obs.shape
!obs_list = list(obs.transpose())
!
!# Okay create the KDTree data structure
!
!mytree = scipy.spatial.cKDTree(combined_xyz_arrays)
!
!distances, indices1D = mytree.query(obs_list)
!
!indices3D = numpy.unravel_index(numpy.ravel(indices1D, y_array.size), y_array.shape)
!
!# these are the integer indices that you now pass into the fortran routine. They
!# are the un-raveled 3D index locations nearest the observation point in the 3D array
!
!k = indices3D[0]
!j = indices3D[1]
!i = indices3D[2]
!
!for n in numpy.arange(obs.shape[1]) :
!    print n, obs[0,n], obs[1,n], obs[2,n], z_array[k[n],j[n],i[n]], y_array[k[n],j[n],i[n]], x_array[k[n],j[n],i[n]]
! 
!# END python code
!======================================================================================================'
SUBROUTINE OBS_2_GRID3D(field, obs, xob, yob, zob, xc, yc, zc, ii, jj, kk, hscale, vscale, missing, nobs, nx, ny, nz)
                   
  implicit none

! Passed in variables

  real(kind=8), INTENT(OUT) :: field(nz,ny,nx)    ! 3D analysis passed back to calling routine
      
  integer,      INTENT(IN)  :: nx, ny, nz, nobs  ! grid dimensions
  real(kind=4), INTENT(IN)  :: xob(nobs)         ! x coords for each ob
  real(kind=4), INTENT(IN)  :: yob(nobs)         ! y coords for each ob
  real(kind=4), INTENT(IN)  :: zob(nobs)         ! z coords for each ob      
  real(kind=4), INTENT(IN)  :: obs(nobs)         ! obs 
  real(kind=4), INTENT(IN)  :: ii(nobs)          ! nearest index to the x-point on grid for ob
  real(kind=4), INTENT(IN)  :: jj(nobs)          ! nearest index to the x-point on grid for o 
  real(kind=4), INTENT(IN)  :: kk(nobs)          ! nearest index to the x-point on grid for o 
  real(kind=4), INTENT(IN)  :: xc(nz,ny,nx)       ! coordinates corresponding to WRF model grid locations
  real(kind=4), INTENT(IN)  :: yc(nz,ny,nx)      ! coordinates corresponding to WRF model grid locations
  real(kind=4), INTENT(IN)  :: zc(nz,ny,nx)      ! coordinates corresponding to WRF model grid locations
  real(kind=4), INTENT(IN)  :: hscale, vscale
  real(kind=4), INTENT(IN)  :: missing
  
! Local variables

  integer i, j, k, i0, j0, k0, n, i0m, i0p, j0m, j0p, k0m, k0p, idx, jdx, kdx      ! loop variables
  
  real(kind=8) dh, dv, wgt
  real(kind=4), allocatable, dimension(:,:,:) :: sum, wgt_sum

! DEBUG
  logical, parameter :: debug = .false.
  
! Allocate local memory

  allocate(wgt_sum(nz, ny, nx))
  allocate(sum(nz, ny, nx))

! Initialize values

  field(:,:,:)   = missing  
  wgt_sum(:,:,:) = 0.0
  sum(:,:,:)     = 0.0

  IF( debug) THEN
    print *, "FORTRAN OBS_2_GRID3D:  dims  ", nx, ny, nz, nobs
    print *, "FORTRAN OBS_2_GRID3D:  dx, hscale", xc(1,1,2) - xc(1,1,1), hscale
    print *, "FORTRAN OBS_2_GRID3D:  dy, hscale", yc(1,2,1) - yc(1,1,1), hscale
    print *, "FORTRAN OBS_2_GRID3D:  vscale  ", vscale
    print *, "FORTRAN OBS_2_GRID3D:    obs ", minval(obs), maxval(obs)
    print *, "FORTRAN OBS_2_GRID3D:  x-obs ", minval(xob), maxval(xob)
    print *, "FORTRAN OBS_2_GRID3D:  y-obs ", minval(yob), maxval(yob)
    print *, "FORTRAN OBS_2_GRID3D:  z-obs ", minval(zob), maxval(zob)
    print *, "FORTRAN OBS_2_GRID3D:  x-grid", minval(xc), maxval(xc)
    print *, "FORTRAN OBS_2_GRID3D:  y-grid", minval(yc), maxval(yc)
    print *, "FORTRAN OBS_2_GRID3D:  z-grid", minval(zc), maxval(zc)
  ENDIF
     
  DO n = 1,nobs
  
    i0 = ii(n)
    j0 = jj(n)
    k0 = kk(n)
    
    if(i0 .eq. 1) cycle
    if(j0 .eq. 1) cycle

    if(i0 .eq. nx) cycle
    if(j0 .eq. ny) cycle    

    idx = 1+nint(hscale/abs(xc(k0,j0,i0) - xc(k0,j0,i0-1)))
    jdx = 1+nint(hscale/abs(yc(k0,j0,i0) - yc(k0,j0-1,i0)))
    
    if( n .eq. 10 ) print *, idx, jdx
    kdx = 3
    
    i0m = max(i0-idx,1)
    j0m = max(j0-jdx,1)
    k0m = max(k0-kdx,1)
    
    i0p = min(i0+idx,nx)
    j0p = min(j0+jdx,ny)
    k0p = min(k0+kdx,nz)

! Do special stuff to populate lowest and highest model levels

    IF (k0 .eq. 1) THEN
       k0m = 1
       k0p = k0p + 1
    ENDIF
        
    IF (k0 .eq. nz) THEN
      k0m = k0m - 1
      k0p = nz
    ENDIF
    
    DO i = i0m, i0p
      DO j = j0m, j0p
        DO k = k0m, k0p
        
          dh = ( (xc(k,j,i)-xob(n))**2 + (yc(k,j,i)-yob(n))**2) / hscale**2
          dv = ( (zc(k,j,i)-zob(n))**2) / vscale**2                                 
          wgt = (1.0 - dh - dv) / (1.0 + dh + dv)
          
          IF (wgt .gt. 0.0) THEN
            sum(k,j,i) = sum(k,j,i) + wgt*obs(n)
            wgt_sum(k,j,i) = wgt_sum(k,j,i) + wgt
          ENDIF  
                    
        ENDDO   ! END K
      ENDDO    ! END J
    ENDDO     ! END I          
  ENDDO      ! END N
 
  WHERE( wgt_sum > 0.01 ) field = sum / wgt_sum
  
  deallocate(wgt_sum)
  deallocate(sum)

RETURN
END SUBROUTINE OBS_2_GRID3D

!############################################################################
!
!     ##################################################################
!     ######                                                      ######
!     ######                SUBROUTINE NO SUPERSAT                ######
!     ######                                                      ######
!     ##################################################################
!
!
!     PURPOSE:
!
!     Limit the level of supersaturation when adding perts
!
!############################################################################
!
!     Author:  Lou Wicker (original code from Dowell in pieces)
!     Date:  Sept 2015
!
!############################################################################

SUBROUTINE NOSUPERSAT(qvnew, pi, theta, qv, nx, ny, nz)

  implicit none

  real(kind=4), intent(OUT) :: qvnew(nz,ny,nx)        ! new limited mixing ratio

  integer,      intent(IN)  :: nx, ny, nz
  real(kind=4), intent(IN)  :: pi(nz,ny,nx)           ! base state Exner function
  real(kind=4), intent(IN)  :: theta(nz,ny,nx)        ! potential temperature (K)
  real(kind=4), intent(IN)  :: qv(nz,ny,nx)           ! water vapor mixing ratio (g/g)

  !---- local variables

  integer i,j,k
  real p            ! pressure (mb)
  real e            ! water vapor pressure (mb)
  real qsat
  real tdc
  real, parameter :: maxsat = 0.99
  
  DO i = 1,nx
   DO j = 1,ny
    DO k = 1,nz
        
     tdc          = theta(k,j,i) - 273.16
     e            = 6.112 * exp(17.67*tdc / (tdc+243.5) )       ! Bolton's approximation
     p            = 1000.*pi(k,j,i)**3.508
     qsat         = 0.622*e / (p-e)
     qvnew(k,j,i) = min(qv(k,j,i), qsat*maxsat)
     
     IF(qvnew(k,j,k) .lt. 0.0 ) THEN
       print *, 'NOSUPERSAT ERROR: ', qvnew(k,j,i), pi(k,j,i), theta(k,j,i), qv(k,j,i), qsat, p, tdc
       STOP
     ENDIF

    ENDDO
   ENDDO
  ENDDO

RETURN
END
