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