
      subroutine init3d(xh,rxh,uh,ruh,xf,rxf,uf,ruf,yh,vh,rvh,yf,vf,rvf,  &
                        xfref,yfref,sigma,c1,c2,gz,                       &
                        zh,mh,rmh,zf,mf,rmf,rho0s,pi0s,prs0s,             &
                        pi0,prs0,rho0,thv0,th0,rth0,qv0,                  &
                        u0,v0,qc0,qi0,rr0,rf0,rrf0,                       &
                        rain,sws,svs,sps,srs,sgs,sus,shs,                 &
                        thflux,qvflux,cd,ch,cq,                           &
                        dum1,dum2,dum3,dum4,divx,rho,prs,                 &
                        t11,t12,t13,t22,t23,t33,                          &
                        rru,ua,u3d,uten,uten1,rrv,va,v3d,vten,vten1,      &
                        rrw,wa,w3d,wten,wten1,ppi,pp3d,ppten,sten,        &
                        tha,th3d,thten,thten1,qa,q3d,qten,                &
                        kmh,kmv,khh,khv,tkea,tke3d,tketen,                &
                        pta,pt3d,ptten,                                   &
                        pdata,cfb,cfa,cfc,ad1,ad2,pdt,deft,rhs,trans)

      use module_mp_nssl_2mom, only: ccn, lccn

      implicit none
 
      include 'input.incl'
      include 'constants.incl'

      real, dimension(ib:ie) :: xh,rxh,uh,ruh
      real, dimension(ib:ie+1) :: xf,rxf,uf,ruf
      real, dimension(jb:je) :: yh,vh,rvh
      real, dimension(jb:je+1) :: yf,vf,rvf
      real, dimension(-2:nx+4) :: xfref
      real, dimension(-2:ny+4) :: yfref
      real, intent(in), dimension(kb:ke) :: sigma
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: c1,c2
      real, intent(in), dimension(itb:ite,jtb:jte) :: gz
      real, dimension(ib:ie,jb:je,kb:ke) :: zh,mh,rmh
      real, dimension(ib:ie,jb:je,kb:ke+1) :: zf,mf,rmf
      real, dimension(ib:ie,jb:je) :: rho0s,pi0s,prs0s
      real, dimension(ib:ie,jb:je,kb:ke) :: pi0,prs0,rho0,thv0,th0,rth0,qv0
      real, dimension(ib:ie,jb:je,kb:ke) :: qc0,qi0,rr0,rf0,rrf0
      real, dimension(ib:ie,jb:je,nrain) :: rain,sws,svs,sps,srs,sgs,sus,shs
      real, dimension(ib:ie,jb:je) :: thflux,qvflux,cd,ch,cq
      real, dimension(ib:ie,jb:je,kb:ke) :: dum1,dum2,dum3,dum4
      real, dimension(ib:ie,jb:je,kb:ke) :: divx,rho,prs
      real, dimension(ib:ie,jb:je,kb:ke) :: t11,t12,t13,t22,t23,t33
      real, dimension(ib:ie+1,jb:je,kb:ke) :: u0,rru,ua,u3d,uten,uten1
      real, dimension(ib:ie,jb:je+1,kb:ke) :: v0,rrv,va,v3d,vten,vten1
      real, dimension(ib:ie,jb:je,kb:ke+1) :: rrw,wa,w3d,wten,wten1
      real, dimension(ib:ie,jb:je,kb:ke) :: ppi,pp3d,ppten,sten
      real, dimension(ib:ie,jb:je,kb:ke) :: tha,th3d,thten,thten1
      real, dimension(ibm:iem,jbm:jem,kbm:kem,numq) :: qa,q3d,qten
      real, dimension(ibc:iec,jbc:jec,kbc:kec) :: kmh,kmv,khh,khv
      real, dimension(ibt:iet,jbt:jet,kbt:ket) :: tkea,tke3d,tketen
      real, dimension(ibp:iep,jbp:jep,kbp:kep,npt) :: pta,pt3d,ptten
      real, dimension(npvals,nparcels) :: pdata
      real, dimension(ipb:ipe,jpb:jpe,kpb:kpe) :: cfb
      real, dimension(kpb:kpe) :: cfa,cfc,ad1,ad2
      complex, dimension(ipb:ipe,jpb:jpe,kpb:kpe) :: pdt,deft
      complex, dimension(ipb:ipe,jpb:jpe) :: rhs,trans
 
!-----------------------------------------------------------------------

      integer i,j,k,l,n,nn,nbub,nloop
      integer ic,jc,ifoo,jfoo
      real ric,rjc
      real xc,yc,zc,bhrad,bvrad,bptpert,beta,omega,tmp,zdep
      real thvnew(nk),pinew(nk)
      real thl,ql,qt,th1,t1,ql2,rm,cpm,v1,v2,th2

      real, dimension(:), allocatable :: rref
      real, dimension(:,:), allocatable :: vref,piref,thref,thvref,qvref
      double precision :: rmax,vmax,frac,angle
      real :: r0,zdd,dd2,dd1,vr,rr,diff,xref,yref,xmax,ymax
      real :: mult,nominal_dx
      integer :: ival,ni1,ni2,ni3
      integer :: i1,i2,ii,jj,nref

      real rmin,foo1,foo2,umax,umin,vmin
      real :: rand,amplitude
      integer, dimension(:), allocatable :: sand
      double precision :: dpi

      logical :: setppi,maintain_rh

      real :: rm1,rm2,rm3,rdc,w2,w3,v3

!--------------------------

      real rslf

      if(dowr) write(outfile,*) 'Inside INIT3D'
      if(dowr) write(outfile,*)

      convinit = 0
      setppi = .true.
      maintain_rh = .false.

!------------------------------------------------------------------
!  Initialize surface swath arrays:

      do n=1,nrain
      do j=jb,je
      do i=ib,ie
        ! these are all positive-definite, so set initial value to zero:
        rain(i,j,n)=0.0
        sws(i,j,n)=0.0
        srs(i,j,n)=0.0
        sgs(i,j,n)=0.0
        shs(i,j,n)=0.0
        ! for sps, we want to get a MINIMUM value at the surface, so...
        ! set sps to an absurdly large number:
        sps(i,j,n)=200000.0
        ! svs and sus can be negative or positive, 
        ! but we want to get a MAXIMUM value, so...
        ! set svs and sus to an absurdly low (negative) number:
        svs(i,j,n)=-1000.0
        sus(i,j,n)=-1000.0
      enddo
      enddo
      enddo

!-----------------------------------------------------------------------
!  Set winds to base-state values:

      do k=kb,ke
      do j=jb,je
      do i=ib,ie+1
        ua(i,j,k)=u0(i,j,k)
        u3d(i,j,k)=u0(i,j,k)
      enddo
      enddo
      enddo

      do k=kb,ke
      do j=jb,je+1
      do i=ib,ie
        va(i,j,k)=v0(i,j,k)
        v3d(i,j,k)=v0(i,j,k)
      enddo
      enddo
      enddo

!-----------------------------------------------------------------------

    IF ( ptype .ge. 26 .and. lccn .gt. 0 ) THEN
! initialize CCN concentrations as constant mixing ratios througout the domain
      do k=kbm,kem
      do j=jbm,jem
      do i=ibm,iem
       qa (i,j,k,lccn-1) = ccn/1.225
       q3d(i,j,k,lccn-1) = ccn/1.225
      enddo
      enddo
      enddo
    ENDIF

!-----------------------------------------------------------------------
!  Set qv to base state value:

    IF(imoist.eq.1)THEN

      do k=kbm,kem
      do j=jbm,jem
      do i=ibm,iem
        qa(i,j,k,nqv)=qv0(i,j,k)
      enddo
      enddo
      enddo

!---- This is here to ensure that certain idealized cases work ----

      IF( (isnd.eq.4 .or. isnd.eq.9 .or. isnd.eq.10 .or. isnd.eq.11) )THEN

        do k=kbm,kem
        do j=jbm,jem
        do i=ibm,iem
          qa(i,j,k,nqc)=qc0(i,j,k)
        enddo
        enddo
        enddo

      ENDIF

      IF( (isnd.eq.4 .or. isnd.eq.9 .or. isnd.eq.10) .and. iice.eq.1 )THEN

        do k=kbm,kem
        do j=jbm,jem
        do i=ibm,iem
          qa(i,j,k,nqi)=qi0(i,j,k)
        enddo
        enddo
        enddo

      ENDIF

    ENDIF

!-----

    IF(iptra.eq.1)THEN
      ! define concentrations for passive fluid tracers here:
      do n=1,npt
      do k=kbp,kep
      do j=jbp,jep
      do i=ibp,iep
        if(n.eq.1)then
          pta(i,j,k,n)=0.0
          if(zh(i,j,k).lt.3000.0) pta(i,j,k,n)=0.001
        endif
        if(n.eq.2)then
          pta(i,j,k,n)=0.0
          if(zh(i,j,k).gt.3000.0.and.zh(i,j,k).lt.6000.0) pta(i,j,k,n)=0.001
        endif
        if(n.eq.3)then
          pta(i,j,k,n)=0.0
          if(zh(i,j,k).gt.6000.0.and.zh(i,j,k).lt.9000.0) pta(i,j,k,n)=0.001
        endif
      enddo
      enddo
      enddo
      enddo
    ENDIF

!-----
!  parcel info:

      IF(iprcl.eq.1)THEN
        ! define initial locations of parcels here:
        !   pdata(1,*) = x location (m)
        !   pdata(2,*) = y location (m)
        !   pdata(3,*) = z location (m)

        if(dowr) write(outfile,*)
        if(dowr) write(outfile,*) '  Parcels ! '
        if(dowr) write(outfile,*) '  npvals,nparcels = ',npvals,nparcels
        if(dowr) write(outfile,*) '  Initial parcel locations (x,y,z):'
        n = 0
        do k=1,10
        do j=1,60
        do i=1,60
          n = n + 1
          if(n.gt.nparcels)then
            if(dowr) write(outfile,*)
            if(dowr) write(outfile,*) ' You are trying to define too many parcels'
            if(dowr) write(outfile,*)
            if(dowr) write(outfile,*) ' Increase the value of nparcels in namelist.input'
            if(dowr) write(outfile,*)
            call stopcm1
          endif
          pdata(1,n) = minx + 2000.0*(i-1)
          pdata(2,n) = miny + 2000.0*(j-1)
          pdata(3,n) = zh(1,1,1) + 1000.0*(k-1)
!!!          if(dowr) write(outfile,*) n,pdata(1,n),pdata(2,n),pdata(3,n)
        enddo
        enddo
        enddo
        if(dowr) write(outfile,*)

      ENDIF

!-----------------------------------------------------------------------
!  initialize random number generator:

        !-----------------------------------!
        !----- don't change this code) -----!
        ! initialize the random number generator
        call random_seed(size=k)
        k = max(2,k)
        if(dowr) write(outfile,*) '  seed_size = ',k
        allocate( sand(k) )
        do n=1,k
          sand(n) = nint( 2.0e9*(2.0*float(n-1)/float(k-1)-1.0) )
        enddo
        call random_seed(put=sand(1:k))
        call random_number(rand)
        if(dowr) write(outfile,*) '  rand-1 = ',rand
        deallocate( sand )
        !----- don't change this code) -----!
        !-----------------------------------!

!-----------------------------------------------------------------------
!  iinit = 1
!  Warm bubble
!  reference:

      IF(iinit.eq.1)THEN

        if(dowr) write(outfile,*)
        if(dowr) write(outfile,*) '  Warm bubble'
        if(dowr) write(outfile,*)

        ric     =      0.0  ! center of bubble in x-direction (m)
        rjc     =      0.0  ! center of bubble in y-direction (m)
        zc      =   1400.0  ! height of center of bubble above ground (m)
        bhrad   =  10000.0  ! horizontal radius of bubble (m)
        bvrad   =   1400.0  ! vertical radius of bubble (m)
        bptpert =      1.0  ! max potential temp perturbation (K)

        ! By default, CM1 sets qv=constant at a constant height level for 
        ! this value of iinit.  If you would rather have rh=constant at 
        ! a constant height level, then set this to .true.
        maintain_rh = .false.

        do k=1,nk
        do j=1,nj
        do i=1,ni
          beta=sqrt(                             &
                    ((xh(i)-ric)/bhrad)**2       &
                   +((yh(j)-rjc)/bhrad)**2       &
                   +((zh(i,j,k)-zc)/bvrad)**2)
          if(beta.lt.1.0)then
            tha(i,j,k)=bptpert*(cos(0.5*pi*beta)**2)
          else
            tha(i,j,k)=0.0
          endif
        enddo
        enddo
        enddo

!-----------------------------------------------------------------------
!  iinit = 2
!  Cold pool (dam break style)
!  reference:  

      ELSEIF(iinit.eq.2)THEN

        if(dowr) write(outfile,*)
        if(dowr) write(outfile,*) '  Cold pool .... periodic in N-S'
        if(dowr) write(outfile,*)

        ric      =  200000.0   ! eastern edge of cold pool
        zdep     =    2500.0   ! depth of cold pool (m)
        bptpert  =      -6.0   ! max temp perturbation at sfc (K)

        ! By default, CM1 sets qv=constant at a constant height level for 
        ! this value of iinit.  If you would rather have rh=constant at 
        ! a constant height level, then set this to .true.
        maintain_rh = .true.

        do k=1,nk
        do j=1,nj
        do i=1,ni
          if( (xh(i).le.ric).and.(zh(i,j,k).lt.zdep) )then
            tha(i,j,k)=bptpert*(zdep-zh(i,j,k))/zdep
          else
            tha(i,j,k)=0.0
          endif
        enddo
        enddo
        enddo


!-----------------------------------------------------------------------
!  iinit = 3
!  Line of warm bubbles
!  reference:  

      ELSEIF(iinit.eq.3)THEN

        if(dowr) write(outfile,*)
        if(dowr) write(outfile,*) '  Line of warm bubbles'
        if(dowr) write(outfile,*)
 
        nbub    =      3     ! number of warm bubbles
        ric     =  30000.0   ! center of bubble in x-direction (m)
        zc      =   1400.0   ! height of center of bubble above ground (m)
        bhrad   =  10000.0   ! horizontal radius of bubble (m)
        bvrad   =   1400.0   ! vertical radius of bubble (m)
        bptpert =      2.0   ! max potential temp perturbation (K)

        ! By default, CM1 sets qv=constant at a constant height level for 
        ! this value of iinit.  If you would rather have rh=constant at 
        ! a constant height level, then set this to .true.
        maintain_rh = .false.

        do k=kb,ke
        do j=jb,je
        do i=ib,ie
          tha(i,j,k)=0.0
        enddo
        enddo
        enddo

        do n=1,nbub

          if(n.eq.1) rjc=  3000.0
          if(n.eq.2) rjc= 33000.0
          if(n.eq.3) rjc= 63000.0

          if(dowr) write(outfile,*) '  ric,rjc=',n,ric,rjc
 
          do k=kb,ke
          do j=jb,je
          do i=ib,ie
            beta=sqrt(                        &
                    ((xh(i)-ric)/bhrad)**2    &
                   +((yh(j)-rjc)/bhrad)**2    &
                   +((zh(i,j,k)-zc)/bvrad)**2)
            if(beta.lt.1.0)then
              tha(i,j,k)=bptpert*(cos(0.5*pi*beta)**2)
            else
              tha(i,j,k)=max(0.0,tha(i,j,k))
            endif
          enddo
          enddo
          enddo

        enddo


!-----------------------------------------------------------------------
!  iinit = 4
!  moist bubble for moist benchmark
!  reference:  Bryan and Fritsch, 2002, MWR, 130, 2917-2928.

      ELSEIF(iinit.eq.4)THEN

        ! parameters for dry counterpart bubble

        ric      =      0.0       ! x-location of bubble center (m)
        zc       =   2000.0       ! z-location of bubble center (m)
        bhrad    =   2000.0       ! horizontal radius of bubble (m)
        bvrad    =   2000.0       ! vertical radius of bubble (m)
        bptpert  =      2.0       ! maximum potential temp. pert. (K)

        do k=kb,ke
        do j=jb,je
        do i=ib,ie
          beta=sqrt( ((xh(i)-ric)/bhrad)**2    &
                    +((zh(i,j,k)-zc)/bvrad)**2)
          if(beta.lt.1.0)then
            dum1(i,j,k)=bptpert*(cos(0.5*pi*beta)**2)
          else
            dum1(i,j,k)=0.
          endif
        enddo
        enddo
        enddo

        do k=kb,ke
        do j=jb,je
        do i=ib,ie
          tha(i,j,k)=0.
          ppi(i,j,k)=0.
          dum2(i,j,k)=qv0(i,j,k)/(rslf(prs0(i,j,k),th0(i,j,k)*pi0(i,j,k)))
        enddo
        enddo
        enddo

        do nn=1,30
          do k=kb,ke
          do j=jb,je
          do i=ib,ie
            qa(i,j,k,nqv)=dum2(i,j,k)*rslf(prs0(i,j,k),(th0(i,j,k)+tha(i,j,k))*pi0(i,j,k))
          enddo
          enddo
          enddo

          do k=kb,ke
          do j=jb,je
          do i=ib,ie
            qa(i,j,k,nqc)=max(qt_mb-qa(i,j,k,nqv),0.0)
          enddo
          enddo
          enddo

          do k=kb,ke
          do j=jb,je
          do i=ib,ie
            tha(i,j,k)=( (dum1(i,j,k)/300.)+(1.0+qt_mb)/(1.0+qa(i,j,k,nqv)) )  &
               *thv0(i,j,k)*(1.0+qa(i,j,k,nqv))/(1.0+reps*qa(i,j,k,nqv)) - th0(i,j,k)
            if(abs(tha(i,j,k)).lt.1.e-4) tha(i,j,k)=0.
          enddo
          enddo
          enddo
        enddo

        do k=kb,ke
        do j=jb,je
        do i=ib,ie
          qa(i,j,k,nqv)=rslf(prs0(i,j,k),(th0(i,j,k)+tha(i,j,k))*pi0(i,j,k))
          qa(i,j,k,nqc)=max(qt_mb-qa(i,j,k,nqv),0.0)
        enddo
        enddo
        enddo

!-----------------------------------------------------------------
!  iinit = 5
!  density current sim

      ELSEIF(iinit.eq.5)THEN

        if(dowr) write(outfile,*)
        if(dowr) write(outfile,*) '  Cold pool (elipse, following Straka)'
        if(dowr) write(outfile,*)

        ric     =     0.0
        rjc     =     0.0
        zc      =  3000.0
        bhrad   =  4000.0
        bvrad   =  2000.0
        bptpert =   -15.0

        do k=kb,ke
        do j=jb,je
        do i=ib,ie
          beta=sqrt(                           &
                     ((xh(i)-ric)/bhrad)**2    &
!!!                    +((yh(j)-rjc)/bhrad)**2    &
                    +((zh(i,j,k)-zc)/bvrad)**2)
          if(beta.lt.1.0)then
            dum1(i,j,k)=bptpert*(cos(pi*beta)+1.0)*0.5
          else
            dum1(i,j,k)=0.0
          endif
        enddo
        enddo
        enddo

        do k=kb,ke
        do j=jb,je
        do i=ib,ie
          tmp=(th0(i,j,k)*pi0(i,j,k))+dum1(i,j,k)
          tha(i,j,k)=tmp/pi0(i,j,k)-th0(i,j,k)
          if(abs(tha(i,j,k)).lt.1.e-4) tha(i,j,k)=0.0
          ppi(i,j,k)=0.0
        enddo
        enddo
        enddo

!------------------------------------------------------------------
!  Rotunno-Emanuel tropical cyclone vortex
!  (see Rotunno and Emanuel, 1987, JAS, for more information)

      ELSEIF(iinit.eq.7)THEN

        r0     =   412500.0
        rmax   =    82500.0
        vmax   =       15.0
        zdd    =    20000.0

        dd2 = 2.0 * rmax / ( r0 + rmax )

        allocate(  rref(nx)       )
        allocate(  vref(nx,0:nk+1))
        allocate( piref(nx,0:nk+1))
        allocate( thref(nx,0:nk+1))
        allocate(thvref(nx,0:nk+1))
        allocate( qvref(nx,0:nk+1))

          rref=0.0
          vref=0.0
         piref=0.0
         thref=0.0
        thvref=0.0
         qvref=0.0

        IF(ibalance.ne.0)THEN
          if(dowr) write(outfile,*)
          if(dowr) write(outfile,*) ' Please use ibalance = 0 with iinit=7'
          if(dowr) write(outfile,*)
          if(dowr) write(outfile,*) ' ... stopping inside init3d ... '
          if(dowr) write(outfile,*)
          call stopcm1
        ENDIF
        IF(terrain_flag)THEN
          if(dowr) write(outfile,*)
          if(dowr) write(outfile,*) ' iinit=7 is not setup for use with terrain'
          if(dowr) write(outfile,*)
          if(dowr) write(outfile,*) ' ... stopping inside init3d ... '
          if(dowr) write(outfile,*)
          call stopcm1
        ENDIF

        IF(axisymm.eq.1)THEN
          nref = nx
          xref = 0.0
          do i=1,nref
            rref(i) = 0.5*(xfref(i)+xfref(i+1))
          enddo
        ELSE
          nref = nx/2+1
          xref = xfref(nx/2+1)
          yref = yfref(ny/2+1)
          xmax = 0.5*(xfref(nx)+xfref(nx+1))
          ymax = 0.5*(yfref(ny)+yfref(ny+1))
          do i=1,nref
            rref(i) = 0.5*(xfref(nx/2+i)+xfref(nx/2+i+1))-xref
          enddo
        ENDIF

!!!        print *
!!!        print *,'  v:'
        do k=1,nk
        do i=1,nref
          if(rref(i).lt.r0)then
            dd1 = 2.0 * rmax / ( rref(i) + rmax )
            vr = sqrt( vmax**2 * (rref(i)/rmax)**2     &
            * ( dd1 ** 3 - dd2 ** 3 ) + 0.25*fcor*fcor*rref(i)*rref(i) )   &
                    - 0.5 * fcor * rref(i)
          else
            vr = 0.0
          endif
!-------------------------------------------
!  alternative:  modified Rankine vortex
!          rm1  =   15000.0
!          rm2  = 2000000.0
!          rm3  = 8000000.0
!          vmax =   80.0
!          rdc  =  -0.50
!          if( rref(i).lt.rm1 )then
!            vr = vmax*rref(i)/rm1
!          elseif( rref(i).lt.rm2 )then
!            vr = vmax*( (rref(i)/rm1)**rdc )
!          elseif( rref(i).lt.rm3 )then
!            v2 = vmax*( (rref(i)/rm1)**rdc )
!            v3 = vmax*0.5*(1.0-(rref(i)-rm2)/(rm3-rm2))
!            w3 = (rref(i)-rm2)/(rm3-rm2)
!            w2 = 1.0-w3
!            vr = w2*v2+w3*v3
!          else
!            vr = 0.0
!          endif
!-------------------------------------------
          if(zh(1,1,k).lt.zdd)then
            vref(i,k) = vr * (zdd-zh(1,1,k))/(zdd-0.0)
          else
            vref(i,k) = 0.0
          endif
!!!          if(k.eq.1) print *,i,xh(ni/2+i),rref(i),vref(i,k)
        enddo
        enddo
!!!        print *

        do k=1,nk
          dum2(1,1,k)=qv0(1,1,k)/(rslf(prs0(1,1,k),th0(1,1,k)*pi0(1,1,k)))
        enddo

      ! need to iterate for qv to converge:
      DO nloop=1,20

        do k=1,nk
        do i=1,nref
          if(imoist.eq.1)   &
          qvref(i,k) = dum2(1,1,k)*rslf(p00*((pi0(1,1,k)+piref(i,k))**cpdrd),   &
                             (pi0(1,1,k)+piref(i,k))*(th0(1,1,k)+thref(i,k)) )
          thvref(i,k)=(th0(1,1,k)+thref(i,k))*(1.0+reps*qvref(i,k))   &
                                             /(1.0+qvref(i,k))
        enddo
        enddo

!!!        print *,'  pi:'
        do k=1,nk
          piref(nref,k)=0.0
          do i=nref,2,-1
            piref(i-1,k) = piref(i,k)                                       &
         + (rref(i-1)-rref(i))/(cp*0.5*(thvref(i-1,k)+thvref(i,k))) * 0.5 * &
             ( vref(i  ,k)*vref(i  ,k)/rref(i)                              &
              +vref(i-1,k)*vref(i-1,k)/rref(i-1)                            &
               + fcor * ( vref(i,k) + vref(i-1,k) ) )
!!!            if(k.eq.1) print *,i-1,rref(i-1),piref(i-1,k)
          enddo
        enddo
!!!        print *

        do i=1,nref
          piref(i,   0) = piref(i, 1)
          piref(i,nk+1) = piref(i,nk)
        enddo

        do k=2,nk
        do i=1,nref
          thref(i,k) = 0.5*( cp*0.5*(thvref(i,k)+thvref(i,k+1))*(piref(i,k+1)-piref(i,k))*rdz*mf(1,1,k+1)     &
                            +cp*0.5*(thvref(i,k)+thvref(i,k-1))*(piref(i,k)-piref(i,k-1))*rdz*mf(1,1,k) )   &
                          *thv0(1,1,k)/g
          thref(i,k)=(thv0(1,1,k)+thref(i,k))*(1.0+qvref(i,k))/(1.0+reps*qvref(i,k))-th0(1,1,k)
        enddo
        enddo

        k=1
        do i=1,nref
          thref(i,k) = ( cp*0.5*(thvref(i,k)+thvref(i,k+1))*(piref(i,k+1)-piref(i,k))*rdz*mf(1,1,k+1) )   &
                          *thv0(1,1,k)/g
          thref(i,k)=(thv0(1,1,k)+thref(i,k))*(1.0+qvref(i,k))/(1.0+reps*qvref(i,k))-th0(1,1,k)
        enddo

        if(dowr) write(outfile,*) nloop,thref(1,1),qvref(1,1),piref(1,1)

      ENDDO   ! enddo for iteration

        IF(axisymm.eq.1)THEN

          do k=1,nk
          do i=1,ni
             va(i,1,k) =  vref(i,k)
            ppi(i,1,k) = piref(i,k)
            tha(i,1,k) = thref(i,k)
            if(imoist.eq.1) qa(i,1,k,nqv) = qvref(i,k)
          enddo
          enddo

        ELSE

          do j=1,nj+1
          do i=1,ni+1
            ! scalar points:
            rr = sqrt( (xh(i)-xref)**2 + (yh(j)-yref)**2 )
            rr = min( rr , xmax-xref )
            ! need to account for grid stretching.  Do simple search:
            diff = -1.0e20
            ii = 0
            do while( diff.lt.0.0 )
              ii = ii + 1
              if( ii.gt.nref )then
                write(6,*)
                write(6,*) ' ii,nref = ',ii,nref
                write(6,*) ' rr      = ',rr,xmax,xref
                write(6,*) ' rref    = ',rref(ii-1),rref(ii-1)-rr
                write(6,*)
                call stopcm1
              endif
              diff = rref(ii)-rr
            enddo
            i2 = ii
            i1 = i2-1
            frac = (      rr-rref(i1))   &
                  /(rref(i2)-rref(i1))
            do k=1,nk
              ppi(i,j,k) = piref(i1,k)+(piref(i2,k)-piref(i1,k))*frac
              tha(i,j,k) = thref(i1,k)+(thref(i2,k)-thref(i1,k))*frac
              if(imoist.eq.1) qa(i,j,k,nqv) = qvref(i1,k)+(qvref(i2,k)-qvref(i1,k))*frac
            enddo

            ! u:
            rr = sqrt( (xf(i)-xref)**2 + (yh(j)-yref)**2 )
            rr = min( rr , xmax-xref )
            ! need to account for grid stretching.  Do simple search:
            diff = -1.0e20
            ii = 0
            do while( diff.lt.0.0 )
              ii = ii + 1
              if( ii.gt.nref )then
                write(6,*)
                write(6,*) ' ii,nref = ',ii,nref
                write(6,*) ' rr      = ',rr,xmax,xref
                write(6,*)
                call stopcm1
              endif
              diff = rref(ii)-rr
            enddo
            if( abs(rr-rref(ii)).lt.tsmall .and. ii.eq.1 ) ii = 2
            i2 = ii
            i1 = i2-1
            frac = (      rr-rref(i1))   &
                  /(rref(i2)-rref(i1))
            do k=1,nk
              angle = datan2(dble(yh(j)-yref),dble(xf(i)-xref))
              ua(i,j,k) = -( vref(i1,k)+( vref(i2,k)- vref(i1,k))*frac )*sin(angle)
            enddo

            ! v:
            rr = sqrt( (yf(j)-yref)**2 + (xh(i)-xref)**2 )
            rr = min( rr , xmax-xref )
            ! need to account for grid stretching.  Do simple search:
            diff = -1.0e20
            ii = 0
            do while( diff.lt.0.0 )
              ii = ii + 1
              if( ii.gt.nref )then
                write(6,*)
                write(6,*) ' ii,nref = ',ii,nref
                write(6,*) ' rr      = ',rr,xmax,xref
                write(6,*)
                call stopcm1
              endif
              diff = rref(ii)-rr
            enddo
            if( abs(rr-rref(ii)).lt.tsmall .and. ii.eq.1 ) ii = 2
            i2 = ii
            i1 = i2-1
            frac = (      rr-rref(i1))   &
                  /(rref(i2)-rref(i1))
            do k=1,nk
              angle = datan2(dble(yf(j)-yref),dble(xh(i)-xref))
              va(i,j,k) = (vref(i1,k)+( vref(i2,k)- vref(i1,k))*frac )*cos(angle)
            enddo
          enddo
          enddo

!!!          print *
!!!          print *,'  symmtest:'
!!!          j = nj/2 + 5
!!!          k = 1
!!!          do i=1,nref
!!!            print *,i,j,ua(i,j,k),va(j,i,k),ua(i,j,k)+va(j,i,k)
!!!          enddo
!!!          print *

        ENDIF

        call bcu(ua)
        call bcv(va)
        call bcs(ppi)
        call bcs(tha)

        call calcprs(pi0,prs,ppi)

        deallocate(  rref)
        deallocate(  vref)
        deallocate( piref)
        deallocate( thref)
        deallocate(thvref)
        deallocate( qvref)

        setppi = .false.

      !-----------------------------------
      ! add random theta perts for 3d runs:
      ! (plus or minus this value in K)

      IF( nx.gt.3 .and. ny.gt.3 )THEN

        amplitude = 0.1

        do k=1,nk
          ! cm1r17: loop over entire domain
          do jj=1,ny
          do ii=1,nx
            call random_number(rand)
            i = ii - (myi-1)*ni
            j = jj - (myj-1)*nj
            ! check to see if this processor has this gridpoint:
            IF( i.ge.ib .and. i.le.ie .and. j.ge.jb .and. j.le.je )THEN
              ! only add perts in the warm core:
              if( tha(i,j,k).ge.0.1 )  &
              tha(i,j,k)=tha(i,j,k)+amplitude*(2.0*rand-1.0)
            ENDIF
          enddo
          enddo
        enddo

      ENDIF

!-----------------------------------------------------------------------
!  iinit = 8
!  Line thermal with random small-amplitude perturbations

      ELSEIF(iinit.eq.8)THEN

        if(dowr) write(outfile,*)
        if(dowr) write(outfile,*) '  Warm bubble'
        if(dowr) write(outfile,*)

        ric     = 150000.0  ! center of bubble in x-direction (m)
        zc      =   1500.0  ! height of center of bubble above ground (m)
        bhrad   =  10000.0  ! horizontal radius of bubble (m)
        bvrad   =   1500.0  ! vertical radius of bubble (m)
        bptpert =      2.0  ! max potential temp perturbation (K)

        ! By default, CM1 sets qv=constant at a constant height level for 
        ! this value of iinit.  If you would rather have rh=constant at 
        ! a constant height level, then set this to .true.
        maintain_rh = .false.

        ! amplitude of random perturbations:
        amplitude = 0.20

        do k=1,nk
        do jj=1,ny
        do ii=1,nx
          call random_number(rand)
          i = ii - (myi-1)*ni
          j = jj - (myj-1)*nj
        IF( i.ge.ib .and. i.le.ie .and. j.ge.jb .and. j.le.je )THEN
          beta=sqrt(                             &
                    ((xh(i)-ric)/bhrad)**2       &
                   +((zh(i,j,k)-zc)/bvrad)**2)
          if(beta.lt.1.0)then
            tha(i,j,k)=bptpert*(cos(0.5*pi*beta)**2)   &
                      +amplitude*(2.0*rand-1.0)
          else
            tha(i,j,k)=0.0
          endif
        ENDIF
        enddo
        enddo
        enddo

!------------------------------------------------------------------
!  iinit = 9
!  Forced convergence
!  Reference:  Loftus et al, 2008: MWR, v. 136, pp. 2408--2421.

      ELSEIF(iinit.eq.9)THEN

        ! User-defined settings:
        Dmax     =  -1.0e-3     ! maximum divergence (s^{-1})
        zdeep    =  2000.0      ! depth (m) of forced convergence
        lamx     = 10000.0      ! Loftus et al lambda_x parameter
        lamy     = 10000.0      ! Loftus at al lambda_y parameter
        xcent    =     0.0      ! x-location (m)
        ycent    =     0.0      ! y-location (m)
        convtime =   900.0      ! time (s) at beginning of simulation over
                                ! which convergence is applied

        ! Don't change anything below here:
        convinit = 1
        IF( ny.eq.1 )THEN
          ! 2D (x-z):
          Aconv = (-0.5*Dmax)/( (1.0/(lamx**2)) )
          lamy = 1.0e20
        ELSEIF( nx.eq.1 )THEN
          ! 2D (y-z):
          Aconv = (-0.5*Dmax)/( (1.0/(lamy**2)) )
          lamx = 1.0e20
        ELSE
          ! 3D:
          Aconv = (-0.5*Dmax)/( (1.0/(lamx**2))+(1.0/(lamy**2)) )
        ENDIF

!------------------------------------------------------------------
!  iinit = 10
!  momentum (u) forcing scheme (Morrison et al, 2015, JAS, pg 315)

      ELSEIF(iinit.eq.10)THEN

        xc_uforce     =  minx + 0.5*(maxx-minx)    ! x_c (m), center point of forcing in x
        xr_uforce     =  10000.0                   ! x_r (m), radius of forcing in x
        zr_uforce     =  10000.0                   ! z_r (m), radius of forcing in z
        alpha_uforce  =    0.1                     ! alpha (m/s/s), max intensity of forcing
        t1_uforce     =  3300.0                    ! time (s) to start ramping down u-forcing
        t2_uforce     =  3600.0                    ! time (s) to turn off u-forcing

!------------------------------------------------------------------
!  iinit = 11
!  Potential-temperature perturbation for inertia-gravity wave test case.
!  Reference:  Skamarock and Klemp, 1994, MWR, 122, 2623-2630.

      ELSEIF(iinit.eq.11)THEN

        do k=1,nk
        do j=1,nj
        do i=1,ni
          !----------
          ! Skamarock-Klemp-94 nonhydrostatic-scale inertia-gravity wave test:
          tha(i,j,k)=0.01*(sin(pi*zh(i,j,k)/10000.0))   &
                         /(1.0+((xh(i)-100000.0)/5000.0)**2)
          !----------
          ! Skamarock-Klemp-94 hydrostatic-scale inertia-gravity wave test:
!!!          tha(i,j,k)=0.01*(sin(pi*zh(i,j,k)/10000.0))   &
!!!                         /(1.0+((xh(i)-0.0)/100000.0)**2)
          !----------
        enddo
        enddo
        enddo

!------------------------------------------------------------------

      ENDIF    ! end of iinit options

!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

! Random perturbations:

      IF( irandp.eq.1 )THEN

        ! this is the amplitude of the theta perturbations
        ! (plus or minus this value in K)
        amplitude = 0.25

        ! random numbers added here
        ! (can be modified to only place perturbations in certain
        !  locations, but this default code simply puts them
        !  everywhere)
        do k=1,nk
          ! cm1r17: loop over entire domain
          do jj = 0,ny+1
          do ii = 0,nx+1
            call random_number(rand)
            i = ii - (myi-1)*ni
            j = jj - (myj-1)*nj
            ! check to see if this processor has this gridpoint:
            IF( i.ge.ib .and. i.le.ie .and. j.ge.jb .and. j.le.je )THEN
              tha(i,j,k)=tha(i,j,k)+amplitude*(2.0*rand-1.0)
            ENDIF
          enddo
          enddo
        enddo

      ENDIF

!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

!----------------------------------------------
!  arrays for elliptic solver

      IF( (ibalance.eq.2).or.(psolver.eq.4).or.(psolver.eq.5) )THEN

        dpi = 4.0d0*datan(1.0d0)
        if(dowr) write(outfile,*) '  dpi = ',dpi

        IF(psolver.le.3)THEN
          do k=1,nk
            cfa(k)=mh(1,1,k)*mf(1,1,k  )*rf0(1,1,k  )*0.5*(thv0(1,1,k-1)+thv0(1,1,k))/(dz*dz*rho0(1,1,k)*thv0(1,1,k))
            cfc(k)=mh(1,1,k)*mf(1,1,k+1)*rf0(1,1,k+1)*0.5*(thv0(1,1,k)+thv0(1,1,k+1))/(dz*dz*rho0(1,1,k)*thv0(1,1,k))
            ad1(k) = 1.0/(cp*rho0(1,1,k)*thv0(1,1,k))
            ad2(k) = 1.0
          enddo
          cfa( 1) = 0.0
          cfc(nk) = 0.0
          do j=jpb,jpe
          do i=ipb,ipe
            do k=1,nk
              cfb(i,j,k)=2.0d0*( dcos(2.0d0*dpi*dble(i-1)/dble(ipe))          &
                                +dcos(2.0d0*dpi*dble(j-1)/dble(jpe))          &
                                -2.0d0)/(dx*dx) - cfa(k) - cfc(k)
            enddo
          enddo
          enddo
        ELSE
          do k=1,nk
            cfa(k)=mh(1,1,k)*mf(1,1,k  )*rf0(1,1,k  )/(dz*dz*rho0(1,1,k-1))
            cfc(k)=mh(1,1,k)*mf(1,1,k+1)*rf0(1,1,k+1)/(dz*dz*rho0(1,1,k+1))
            ad1(k) = 1.0
            ad2(k) = 1.0/rho0(1,1,k)
          enddo
          cfa( 1) = 0.0
          cfc(nk) = 0.0
          do j=jpb,jpe
          do i=ipb,ipe
            do k=2,nk-1
              cfb(i,j,k)=2.0d0*( dcos(2.0d0*dpi*dble(i-1)/dble(ipe))          &
                                +dcos(2.0d0*dpi*dble(j-1)/dble(jpe))          &
                                -2.0d0)/(dx*dx)                               &
                    -mh(1,1,k)*mf(1,1,k+1)*rf0(1,1,k+1)/(dz*dz*rho0(1,1,k))   &
                    -mh(1,1,k)*mf(1,1,k  )*rf0(1,1,k  )/(dz*dz*rho0(1,1,k))
            enddo
            cfb(i,j,1)=2.0d0*( dcos(2.0d0*dpi*dble(i-1)/dble(ipe))          &
                              +dcos(2.0d0*dpi*dble(j-1)/dble(jpe))          &
                              -2.0d0)/(dx*dx)                               &
                  -mh(1,1,1)*mf(1,1,2  )*rf0(1,1,2  )/(dz*dz*rho0(1,1,1))
            cfb(i,j,nk)=2.0d0*( dcos(2.0d0*dpi*dble(i-1)/dble(ipe))          &
                              +dcos(2.0d0*dpi*dble(j-1)/dble(jpe))          &
                              -2.0d0)/(dx*dx)                               &
                  -mh(1,1,nk)*mf(1,1,nk  )*rf0(1,1,nk  )/(dz*dz*rho0(1,1,nk))
          enddo
          enddo
        ENDIF

      ENDIF

!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

!-----------------------------------------------------------------
!  Get 3d pressure
        
      if(imoist.eq.1 .and. maintain_rh)then

        !! maintain rh
        if(dowr) write(outfile,*)
        if(dowr) write(outfile,*) '  Constant rh across domain:'
        if(dowr) write(outfile,*)

        do k=kb,ke
        do j=jb,je
        do i=ib,ie
          dum2(i,j,k)=qv0(i,j,k)/(rslf(prs0(i,j,k),th0(i,j,k)*pi0(i,j,k)))
          qa(i,j,k,nqv)=dum2(i,j,k)*rslf(prs0(i,j,k),(th0(i,j,k)+tha(i,j,k))*pi0(i,j,k))
        enddo
        enddo
        enddo

      endif


    IF(setppi)THEN

      do k=kb,ke
      do j=jb,je
      do i=ib,ie
        ppi(i,j,k)=0.0
      enddo
      enddo
      enddo

      IF(ibalance.eq.1)THEN

        ! hydrostatic balance ... integrate top-down

        do j=1,nj
        do i=1,ni
          ! virtual potential temperature

          if(imoist.eq.1)then
            do k=1,nk
              qt=0.0
              do n=nql1,nql2
                qt=qt+qa(i,j,k,n)
              enddo
              if(iice.eq.1)then
                do n=nqs1,nqs2
                  qt=qt+qa(i,j,k,n)
                enddo
              endif
              thvnew(k)=(th0(i,j,k)+tha(i,j,k))*(1.0+reps*qa(i,j,k,nqv))   &
                                               /(1.0+qa(i,j,k,nqv)+qt)
            enddo
          else
            do k=1,nk
              thvnew(k)=th0(i,j,k)+tha(i,j,k)
            enddo
          endif

          ! non-dimensional pressure
          pinew(nk)=pi0(i,j,nk)
          do k=nk-1,1,-1
            pinew(k)=pinew(k+1)+g*(zh(i,j,k+1)-zh(i,j,k))   &
                    /(cp*0.5*(thvnew(k+1)+thvnew(k)))
          enddo

          ! new pressure
          do k=1,nk
            ppi(i,j,k)=pinew(k)-pi0(i,j,k)
            if(abs(ppi(i,j,k)).lt.1.0e-6) ppi(i,j,k)=0.0
          enddo

        enddo
        enddo

      ELSEIF(ibalance.eq.2)THEN

        if(dowr) write(outfile,*)
        if(dowr) write(outfile,*) '  ibalance = 2'
        if(dowr) write(outfile,*)

        if(stretch_x.ge.1.or.stretch_y.ge.1)then
          print *,'  this option not supported with horizontal grid stretching'
          print *,'  (yet)'
          call stopcm1
        endif


        ! buoyancy pressure

        ! th3d stores theta-v

        if(imoist.eq.1)then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            qt=0.0
            do n=nql1,nql2
              qt=qt+qa(i,j,k,n)
            enddo
            if(iice.eq.1)then
              do n=nqs1,nqs2
                qt=qt+qa(i,j,k,n)
              enddo
            endif
            th3d(i,j,k)=(th0(i,j,k)+tha(i,j,k))*(1.0+reps*qa(i,j,k,nqv))   &
                       /(1.0+qa(i,j,k,nqv)+qt)
          enddo
          enddo
          enddo
        else
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            th3d(i,j,k)=th0(i,j,k)+tha(i,j,k)
          enddo
          enddo
          enddo
        endif

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do j=1,nj
        do i=1,ni
          th3d(i,j,0   ) = th3d(i,j,1)
          th3d(i,j,nk+1) = th3d(i,j,nk)
        enddo
        enddo

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum4(i,j,k)=g*( th3d(i,j,k)/thv0(i,j,k)-1.0 )
        enddo
        enddo
        enddo

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do j=1,nj
        do i=1,ni
          dum4(i,j,0   ) = -dum4(i,j,1)
          dum4(i,j,nk+1) = -dum4(i,j,nk)
        enddo
        enddo

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk+1
        do j=1,nj
        do i=1,ni
          wten(i,j,k)=0.5*( dum4(i,j,k-1)+dum4(i,j,k) )
        enddo
        enddo
        enddo

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=kb,ke
        do j=jb,je
        do i=ib,ie
          ppi(i,j,k)=0.0
          dum3(i,j,k)=0.0
          divx(i,j,k)=0.0
          uten(i,j,k)=0.0
          vten(i,j,k)=0.0
        enddo
        enddo
        enddo

        call poiss(uh,vh,mh,rmh,mf,rmf,pi0,thv0,rho0,rf0,    &
                   dum3,divx,ppi,uten,vten,wten,             &
                   cfb,cfa,cfc,ad1,ad2,pdt,deft,rhs,trans,dtl)

        IF(psolver.eq.4.or.psolver.eq.5.or.psolver.eq.6)THEN

!$omp parallel do default(shared)   &
!$omp private(i,j,k)
          do k=kb,ke
          do j=jb,je
          do i=ib,ie
            ppi(i,j,k)=((prs0(1,1,k)+ppi(i,j,k)*rho0(1,1,k))*rp00)**rovcp   &
                      -pi0(1,1,k)
            pp3d(i,j,k)=ppi(i,j,k)
          enddo
          enddo
          enddo

        ENDIF

        call bcs(ppi)

      ENDIF

    ENDIF

!------------------------------------------------------------------

      if(dowr) write(outfile,*)
      if(dowr) write(outfile,*) 'Leaving INIT3D'

      end subroutine init3d


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine getset(restart,mass1,ruh,rvh,xf,                          &
                        gz,sigma,sigmaf,rmh,mf,dzdx,dzdy,                  &
                        pi0,th0,rho0,prs0,ust,u1,v1,s1,                    &
                        zh,c1,c2,zf,rr,rf,rho,prs,dum1,dum2,               &
                        ua,u3d,va,v3d,wa,w3d,ppi,pp3d,                     &
                        tha,th3d,qa,q3d,tkea,tke3d,pta,pt3d,               &
                        reqs_u,reqs_v,reqs_w,reqs_s,reqs_p,reqs_tk,        &
                        nw1,nw2,ne1,ne2,sw1,sw2,se1,se2,                   &
                        pw1,pw2,pe1,pe2,ps1,ps2,pn1,pn2,                   &
                        uw31,uw32,ue31,ue32,us31,us32,un31,un32,           &
                        vw31,vw32,ve31,ve32,vs31,vs32,vn31,vn32,           &
                        ww31,ww32,we31,we32,ws31,ws32,wn31,wn32,           &
                        sw31,sw32,se31,se32,ss31,ss32,sn31,sn32,           &
                        tkw1,tkw2,tke1,tke2,tks1,tks2,tkn1,tkn2)
      implicit none
 
      include 'input.incl'
      include 'constants.incl'

      logical, intent(in) :: restart
      double precision, intent(inout) :: mass1
      real, intent(in), dimension(ib:ie) :: ruh
      real, intent(in), dimension(jb:je) :: rvh
      real, intent(in), dimension(ib:ie+1) :: xf
      real, intent(in), dimension(itb:ite,jtb:jte) :: gz
      real, intent(in), dimension(kb:ke) :: sigma
      real, intent(in), dimension(kb:ke+1) :: sigmaf
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: rmh
      real, intent(in), dimension(ib:ie,jb:je,kb:ke+1) :: mf
      real, intent(in), dimension(itb:ite,jtb:jte) :: dzdx,dzdy
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: pi0,th0,rho0,prs0
      real, intent(inout), dimension(ib:ie,jb:je) :: ust,u1,v1,s1
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: zh,c1,c2
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: rr,rf
      real, intent(in), dimension(ib:ie,jb:je,kb:ke+1) :: zf
      real, dimension(ib:ie,jb:je,kb:ke) :: rho,prs,dum1,dum2
      real, dimension(ib:ie+1,jb:je,kb:ke) :: ua,u3d
      real, dimension(ib:ie,jb:je+1,kb:ke) :: va,v3d
      real, dimension(ib:ie,jb:je,kb:ke+1) :: wa,w3d
      real, dimension(ib:ie,jb:je,kb:ke) :: ppi,pp3d
      real, dimension(ib:ie,jb:je,kb:ke) :: tha,th3d
      real, dimension(ibm:iem,jbm:jem,kbm:kem,numq) :: qa,q3d
      real, dimension(ibt:iet,jbt:jet,kbt:ket) :: tkea,tke3d
      real, dimension(ibp:iep,jbp:jep,kbp:kep,npt) :: pta,pt3d
      integer, dimension(rmp) :: reqs_u,reqs_v,reqs_w,reqs_s,reqs_p,reqs_tk
      real, intent(inout), dimension(kmt) :: nw1,nw2,ne1,ne2,sw1,sw2,se1,se2
      real, intent(inout), dimension(jmp,kmp) :: pw1,pw2,pe1,pe2
      real, intent(inout), dimension(imp,kmp) :: ps1,ps2,pn1,pn2
      real, dimension(cmp,jmp,kmp)   :: uw31,uw32,ue31,ue32
      real, dimension(imp+1,cmp,kmp) :: us31,us32,un31,un32
      real, dimension(cmp,jmp+1,kmp) :: vw31,vw32,ve31,ve32
      real, dimension(imp,cmp,kmp)   :: vs31,vs32,vn31,vn32
      real, dimension(cmp,jmp,kmp-1) :: ww31,ww32,we31,we32
      real, dimension(imp,cmp,kmp-1) :: ws31,ws32,wn31,wn32
      real, dimension(cmp,jmp,kmp)   :: sw31,sw32,se31,se32
      real, dimension(imp,cmp,kmp)   :: ss31,ss32,sn31,sn32
      real, dimension(cmp,jmp,kmt)   :: tkw1,tkw2,tke1,tke2
      real, dimension(imp,cmp,kmt)   :: tks1,tks2,tkn1,tkn2

!----------
 
      integer :: i,j,k,n
      double precision :: p0

!------------------------------------------------------------------
!  Make sure boundary values are set properly

      if(dowr) write(outfile,*) 'Inside GETSET'
      if(dowr) write(outfile,*)

      call bcu(ua)
      call bcv(va)
      call bcw(wa,1)
      call bcs(ppi)
      call bcs(tha)
      if(imoist.eq.1)then
        do n=1,numq
          call bcs(qa(ibm,jbm,kbm,n))
        enddo
      endif
      if(iturb.eq.1)then
        call bcw(tkea,1)
      endif
      if(iptra.eq.1)then
        do n=1,npt
          call bcs(pta(ib,jb,kb,n))
        enddo
      endif

      if(terrain_flag)then
        call bcwsfc(gz,dzdx,dzdy,ua,va,wa)
        call bc2d(wa(ib,jb,1))
      endif
!------------------------------------------------------------------
!  Get stuff

  IF( .not. restart )THEN

    IF(psolver.eq.4.or.psolver.eq.5.or.psolver.eq.6)THEN

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      do k=1,nk
      do j=1,nj
      do i=1,ni
        rho(i,j,k)=rho0(i,j,k)
        prs(i,j,k)=prs0(i,j,k)
      enddo
      enddo
      enddo

    ELSE

      call calcprs(pi0,prs,ppi)
 
      call calcrho(pi0,th0,rho,prs,ppi,tha,qa)

    ENDIF

  ENDIF


        call bcs(rho)
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do j=0,nj+1
          k = 1
          do i=0,ni+1
            rr(i,j,k) = 1.0/rho(i,j,k)
            ! cm1r17, 2nd-order extrapolation:
            rf(i,j,1) = cgs1*rho(i,j,1)+cgs2*rho(i,j,2)+cgs3*rho(i,j,3)
          enddo
          do k=2,nk
          do i=0,ni+1
            rr(i,j,k) = 1.0/rho(i,j,k)
            rf(i,j,k) = (c1(i,j,k)*rho(i,j,k-1)+c2(i,j,k)*rho(i,j,k))
          enddo
          enddo
          do i=0,ni+1
            ! cm1r17, 2nd-order extrapolation:
            rf(i,j,nk+1) = cgt1*rho(i,j,nk)+cgt2*rho(i,j,nk-1)+cgt3*rho(i,j,nk-2)
          enddo
        enddo

!------------------------------------------------------------------
!  cm1r18:  get total mass of dry air at t=0

      IF( .not. restart )THEN

        mass1 = 0.0

        IF( axisymm.eq.0 )THEN
          do k=1,nk
          do j=1,nj
          do i=1,ni
            mass1 = mass1 + rho(i,j,k)*ruh(i)*rvh(j)*rmh(i,j,k)
          enddo
          enddo
          enddo
        ELSEIF( axisymm.eq.1 )THEN
          do k=1,nk
          do j=1,nj
          do i=1,ni
            mass1 = mass1 + rho(i,j,k)*ruh(i)*rvh(j)*rmh(i,j,k)*pi*(xf(i+1)**2-xf(i)**2)
          enddo
          enddo
          enddo
        ELSE
          stop 2223
        ENDIF

        mass1 = mass1*(dx*dy*dz)

        if( myid.eq.0 ) print *,'  mass1 = ',mass1

      ENDIF

!------------------------------------------------------------------

      do k=kb,ke
      do j=jb,je
      do i=ib,ie+1
        u3d(i,j,k)=ua(i,j,k)
      enddo
      enddo
      enddo
 
      do k=kb,ke
      do j=jb,je+1
      do i=ib,ie
        v3d(i,j,k)=va(i,j,k)
      enddo
      enddo
      enddo
 
      do k=kb,ke+1
      do j=jb,je
      do i=ib,ie
        w3d(i,j,k)=wa(i,j,k)
      enddo
      enddo
      enddo

      do k=kb,ke
      do j=jb,je
      do i=ib,ie
        pp3d(i,j,k)=ppi(i,j,k)
        th3d(i,j,k)=tha(i,j,k)
      enddo
      enddo
      enddo

      if(imoist.eq.1)then
        do n=1,numq
        do k=kb,ke
        do j=jb,je
        do i=ib,ie
          q3d(i,j,k,n)=qa(i,j,k,n)
        enddo
        enddo
        enddo
        enddo
      endif

      if(iturb.eq.1)then
        do k=kbt,ket
        do j=jbt,jet
        do i=ibt,iet
          tke3d(i,j,k)=tkea(i,j,k)
        enddo
        enddo
        enddo
      endif

      if(iptra.eq.1)then
        do n=1,npt
        do k=kb,ke
        do j=jb,je
        do i=ib,ie
          pt3d(i,j,k,n)=pta(i,j,k,n)
        enddo
        enddo
        enddo
        enddo
      endif

      if(dowr) write(outfile,*)
      if(dowr) write(outfile,*) 'Leaving GETSET'
 
      end subroutine getset


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine convinitu(myid,ib,ie,jb,je,kb,ke,ni,nj,nk,ibw,ibe,   &
                           zdeep,lamx,lamy,xcent,ycent,aconv,    &
                           xf,yh,zh,u0,u3d)
      implicit none

      integer, intent(in) :: myid,ib,ie,jb,je,kb,ke,ni,nj,nk,ibw,ibe
      real, intent(in) :: zdeep,lamx,lamy,xcent,ycent,aconv
      real, intent(in), dimension(ib:ie+1) :: xf
      real, intent(in), dimension(jb:je) :: yh
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: zh
      real, intent(in),    dimension(ib:ie+1,jb:je,kb:ke) :: u0
      real, intent(inout), dimension(ib:ie+1,jb:je,kb:ke) :: u3d

      integer :: i,j,k
      real :: term1,term2,term3,term4,umo

!!!      if(myid.eq.0) print *,'    convinitu '
!$omp parallel do default(shared)   &
!$omp private(i,j,k,term1,term2,term3,term4,umo)
      do k=1,nk
      do j=1,nj
      do i=1,ni+1
        term4 = (zdeep-0.5*(zh(i-1,j,k)+zh(i,j,k)))/zdeep
        if (term4 .gt. 0.0) then
          term1 = -(2.0*Aconv*(xf(i)-xcent))/(lamx**2)
          term2 = -((xf(i)-xcent)/lamx)**2
          term3 = -((yh(j)-ycent)/lamy)**2
          umo = term1*(exp(term2)*exp(term3))*term4
          if( abs(umo).gt.0.01 ) u3d(i,j,k) = u0(i,j,k)+umo
        endif
      enddo
      enddo
      enddo

      return
      end subroutine convinitu


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine convinitv(myid,ib,ie,jb,je,kb,ke,ni,nj,nk,ibs,ibn,   &
                           zdeep,lamx,lamy,xcent,ycent,aconv,    &
                           xh,yf,zh,v0,v3d)
      implicit none

      integer, intent(in) :: myid,ib,ie,jb,je,kb,ke,ni,nj,nk,ibs,ibn
      real, intent(in) :: zdeep,lamx,lamy,xcent,ycent,aconv
      real, intent(in), dimension(ib:ie) :: xh
      real, intent(in), dimension(jb:je+1) :: yf
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: zh
      real, intent(in),    dimension(ib:ie,jb:je+1,kb:ke) :: v0
      real, intent(inout), dimension(ib:ie,jb:je+1,kb:ke) :: v3d

      integer :: i,j,k
      real :: term1,term2,term3,term4,vmo

!!!      if(myid.eq.0) print *,'    convinitv '
!$omp parallel do default(shared)   &
!$omp private(i,j,k,term1,term2,term3,term4,vmo)
      do k=1,nk
      do j=1,nj+1
      do i=1,ni
        term4 = (zdeep-0.5*(zh(i,j-1,k)+zh(i,j,k)))/zdeep
        if (term4 .gt. 0.0) then
          term1 = -(2.0*Aconv*(yf(j)-ycent))/(lamy**2)
          term2 = -((xh(i)-xcent)/lamx)**2
          term3 = -((yf(j)-ycent)/lamy)**2
          vmo = term1*(exp(term2)*exp(term3))*term4
          if( abs(vmo).gt.0.01 ) v3d(i,j,k) = v0(i,j,k)+vmo
        endif
      enddo
      enddo
      enddo

      return
      end subroutine convinitv


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
