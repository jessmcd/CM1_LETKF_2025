

      subroutine dtsmall(dt)
      implicit none

      include 'input.incl'
      include 'constants.incl'

      ! cm1r18:  moved this section of code from solve.F to misclibs.F

      real, intent(inout) :: dt

      real :: dtsm

        ! Algorithm to determine number of small steps:
        IF( psolver.eq.2 )THEN
          ! check dx,dy,dz:
          IF( ny.eq.1 )THEN
            ! 2D sims (x-z):
            dtsm = 0.60*min( min_dx , min_dz )/360.0
          ELSEIF( nx.eq.1 )THEN
            ! 2D sims (y-z):
            dtsm = 0.60*min( min_dy , min_dz )/360.0
          ELSE
            ! 3D sims:
            dtsm = 0.50*min( min_dx , min_dy , min_dz )/360.0
          ENDIF
        ELSEIF( psolver.eq.3 )THEN
          ! check dx,dy:
          IF( ny.eq.1 )THEN
            ! 2D sims (x-z):
            dtsm = 0.60*min_dx/360.0
          ELSEIF( nx.eq.1 )THEN
            ! 2D sims (y-z):
            dtsm = 0.60*min_dy/360.0
          ELSE
            ! 3D sims:
            dtsm = 0.60*min( min_dx , min_dy )/360.0
          ENDIF
        ELSEIF( psolver.eq.6 )THEN
          ! check dx,dy,dz:
          IF( ny.eq.1 )THEN
            ! 2D sims (x-z):
            dtsm = 0.60*min( min_dx , min_dz )/csound
          ELSEIF( nx.eq.1 )THEN
            ! 2D sims (y-z):
            dtsm = 0.60*min( min_dy , min_dz )/csound
          ELSE
            ! 3D sims:
            dtsm = 0.50*min( min_dx , min_dy , min_dz )/csound
          ENDIF
        ENDIF

        nsound = max( nint( dt/dtsm ) , 4 )
        if( mod(nsound,2).ne.0 ) nsound = nsound + 1
        if( dt/float(nsound).gt.dtsm ) nsound = nsound + 2

        if( nsound.gt.48 )then
          nsound = 48
          dt = 48*dtsm
        endif

      return
      end


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine getqli(q,ql,qi)
      implicit none

      include 'input.incl'
      include 'timestat.incl'

      real, dimension(ibm:iem,jbm:jem,kbm:kem,numq) :: q
      real, dimension(ib:ie,jb:je,kb:ke) :: ql,qi

      integer :: i,j,k,n

!$omp parallel do default(shared)  &
!$omp private(i,j,k,n)
    DO k=1,nk

      do j=1,nj
      do i=1,ni
        ql(i,j,k)=0.0
        qi(i,j,k)=0.0
      enddo
      enddo

      do n=nql1,nql2
        do j=1,nj
        do i=1,ni
          ql(i,j,k)=ql(i,j,k)+q(i,j,k,n)
        enddo
        enddo
      enddo

      IF(iice.eq.1)THEN
        do n=nqs1,nqs2
          do j=1,nj
          do i=1,ni
            qi(i,j,k)=qi(i,j,k)+q(i,j,k,n)
          enddo
          enddo
        enddo
      ENDIF

    ENDDO

      if(timestats.ge.1) time_misc=time_misc+mytime()

      return
      end


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine getcvm(cvm,q)
      implicit none

      include 'input.incl'
      include 'constants.incl'
      include 'timestat.incl'

      real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: cvm
      real, intent(in), dimension(ibm:iem,jbm:jem,kbm:kem,numq) :: q

      integer :: i,j,k,n

!$omp parallel do default(shared)  &
!$omp private(i,j,k,n)
    DO k=1,nk

      IF( eqtset.le.1 .or. imoist.eq.0 )THEN

        do j=1,nj
        do i=1,ni
          cvm(i,j,k) = cv
        enddo
        enddo

      ELSE

        do j=1,nj
        do i=1,ni
          cvm(i,j,k) = cv+cvv*q(i,j,k,nqv)
        enddo
        enddo
        do n=nql1,nql2
          do j=1,nj
          do i=1,ni
            cvm(i,j,k)=cvm(i,j,k)+cpl*q(i,j,k,n)
          enddo
          enddo
        enddo
        IF(iice.eq.1)THEN
          do n=nqs1,nqs2
          do j=1,nj
          do i=1,ni
            cvm(i,j,k)=cvm(i,j,k)+cpi*q(i,j,k,n)
          enddo
          enddo
          enddo
        ENDIF

      ENDIF

    ENDDO

      if(timestats.ge.1) time_misc=time_misc+mytime()

      return
      end


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine pdefq(rmax,asq,ruh,rvh,rmh,rho,q3d)
      implicit none

      include 'input.incl'
      include 'timestat.incl'

      real rmax
      double precision :: asq
      real, dimension(ib:ie) :: ruh
      real, dimension(jb:je) :: rvh
      real, dimension(ib:ie,jb:je,kb:ke) :: rmh
      real, dimension(ib:ie,jb:je,kb:ke) :: rho,q3d

      integer i,j,k
      double precision :: t1,t2,t3
      double precision :: a1,a2,tem
      double precision, dimension(nj) :: budj
      double precision, dimension(nk) :: budk

!----------------------------------------------------------------------

      tem = dx*dy*dz

      IF(pdscheme.eq.1)THEN

!$omp parallel do default(shared)   &
!$omp private(i,j,k,t1,t2,t3,a1,a2)
        do j=1,nj
        budj(j)=0.0d0
        do i=1,ni
          t1=0.0d0
          t2=0.0d0
          a1=0.0d0
          a2=0.0d0
          do k=1,nk
            t1=t1+rho(i,j,k)*q3d(i,j,k)
            a1=a1+rho(i,j,k)*q3d(i,j,k)*ruh(i)*rvh(j)*rmh(i,j,k)
!!!            q3d(i,j,k)=max(0.0,q3d(i,j,k))
            if(q3d(i,j,k).lt.rmax) q3d(i,j,k)=0.0
            t2=t2+rho(i,j,k)*q3d(i,j,k)
          enddo
          t3=(t1+1.0d-20)/(t2+1.0d-20)
          if(t3.lt.0.0) t3=1.0d0
          do k=1,nk
            q3d(i,j,k)=t3*q3d(i,j,k)
            a2=a2+rho(i,j,k)*q3d(i,j,k)*ruh(i)*rvh(j)*rmh(i,j,k)
          enddo
          budj(j)=budj(j)+a2-a1
        enddo
        enddo

        do j=1,nj
          asq=asq+budj(j)*tem
        enddo

      ELSE

!$omp parallel do default(shared)   &
!$omp private(i,j,k,a1,a2)
        do k=1,nk
        budk(k)=0.0d0
        do j=1,nj
        do i=1,ni
          a1=rho(i,j,k)*q3d(i,j,k)*ruh(i)*rvh(j)*rmh(i,j,k)
!!!          q3d(i,j,k)=max(0.0,q3d(i,j,k))
          if(q3d(i,j,k).lt.rmax) q3d(i,j,k)=0.0
          a2=rho(i,j,k)*q3d(i,j,k)*ruh(i)*rvh(j)*rmh(i,j,k)
          budk(k)=budk(k)+a2-a1
        enddo
        enddo
        enddo

        do k=1,nk
          asq=asq+budk(k)*tem
        enddo

      ENDIF

!----------------------------------------------------------------------

      if(timestats.ge.1) time_misc=time_misc+mytime()

      return
      end


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
 
 
      subroutine calcprs(pi0,prs,pp3d)
      implicit none
 
      include 'input.incl'
      include 'constants.incl'
      include 'timestat.incl'
 
      real, dimension(ib:ie,jb:je,kb:ke) :: pi0
      real, dimension(ib:ie,jb:je,kb:ke) :: prs,pp3d
 
      integer i,j,k
 
!----------------------------------------------------------------------
 
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      do k=1,nk
      do j=1,nj
      do i=1,ni
        prs(i,j,k)=p00*((pi0(i,j,k)+pp3d(i,j,k))**cpdrd)
      enddo
      enddo
      enddo
 
!----------------------------------------------------------------------
 
      if(timestats.ge.1) time_prsrho=time_prsrho+mytime()
 
      return
      end


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine calcrho(pi0,th0,rho,prs,pp3d,th3d,q3d)
      implicit none

      include 'input.incl'
      include 'constants.incl'
      include 'timestat.incl'

      real, dimension(ib:ie,jb:je,kb:ke) :: pi0,th0
      real, dimension(ib:ie,jb:je,kb:ke) :: rho,prs,pp3d,th3d
      real, dimension(ibm:iem,jbm:jem,kbm:kem,numq) :: q3d

      integer i,j,k

!----------------------------------------------------------------------

      IF(imoist.eq.1)THEN

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk
        do j=1,nj
        do i=1,ni
          rho(i,j,k)=prs(i,j,k)                         &
             /( rd*(th0(i,j,k)+th3d(i,j,k))*(pi0(i,j,k)+pp3d(i,j,k))     &
                  *(1.0+max(0.0,q3d(i,j,k,nqv))*reps) )
        enddo
        enddo
        enddo

      ELSE

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk
        do j=1,nj
        do i=1,ni
          rho(i,j,k)=prs(i,j,k)   &
             /(rd*(th0(i,j,k)+th3d(i,j,k))*(pi0(i,j,k)+pp3d(i,j,k)))
        enddo
        enddo
        enddo

      ENDIF

!----------------------------------------------------------------------

      if(timestats.ge.1) time_prsrho=time_prsrho+mytime()

      return
      end


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine calcdbz(rho,qr,qs,qg,dbz)
      implicit none

      include 'input.incl'
      include 'constants.incl'
      include 'timestat.incl'
      include 'goddard.incl'

      real, dimension(ib:ie,jb:je,kb:ke) :: rho,qr,qs,qg,dbz

      integer :: i,j,k
      real :: n0r,n0g,n0s,rhor,rhog,rhos,gamma,zer,zeg,zes
      real, parameter :: epp = 1.0e-8

  IF(ptype.eq.2)THEN

    rhor = 1000.0 * ROQR
    rhog = 1000.0 * ROQG
    rhos = 1000.0 * ROQS

    n0r = 1.0e8 * TNW
    n0g = 1.0e8 * TNG
    n0s = 1.0e8 * TNSS

!!!    print *,'  rhor,rhog,rhos = ',rhor,rhog,rhos
!!!    print *,'  n0r,n0g,n0s    = ',n0r,n0g,n0s

!$omp parallel do default(shared)  &
!$omp private(i,j,k,gamma,zer,zeg,zes)
    do k=1,nk
    do j=1,nj
    do i=1,ni

    if(qr(i,j,k).ge.epp)then
      !--- rain ---
      gamma=(3.14159*n0r*rhor/(rho(i,j,k)*qr(i,j,k)))**0.25
      zer=720.0*n0r*(gamma**(-7))
    else
      zer=0.0
    endif

    if(qg(i,j,k).ge.epp)then
      !--- graupel/hail ---
      gamma=(3.14159*n0g*rhog/(rho(i,j,k)*qg(i,j,k)))**0.25
      zeg=720.0*n0g*(gamma**(-7))*((rhog/rhor)**2)*0.224
    else
      zeg=0.0
    endif

    if(qs(i,j,k).ge.epp)then
      !--- snow ---
      gamma=(3.14159*n0s*rhos/(rho(i,j,k)*qs(i,j,k)))**0.25
      zes=720.0*n0s*(gamma**(-7))*((rhos/rhor)**2)*0.224
    else
      zes=0.0
    endif

      !--- dbz ---

    if( (zer+zeg+zes).gt.1.0e-18 )then
      dbz(i,j,k)=10.0*log10((zer+zeg+zes)*1.0e18)
    else
      dbz(i,j,k)=0.0
    endif

    enddo
    enddo
    enddo

  ELSE

    if(dowr) write(outfile,*)
    if(dowr) write(outfile,*) ' ptype = ',ptype
    if(dowr) write(outfile,*)
    if(dowr) write(outfile,*) ' calcdbz is not valid for this value of ptype'
    if(dowr) write(outfile,*)
    call stopcm1

  ENDIF

      if(timestats.ge.1) time_write=time_write+mytime()

      return
      end


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine impldiffu(uf,vh,arh1,arh2,arf1,arf2,mh,rdsf,gzu,rho0,rr0,dum1,dum2,dum3,rru,rrv,rrw,u3d,uten)
      implicit none

      include 'input.incl'
      include 'constants.incl'
      include 'timestat.incl'

      real, intent(in),    dimension(ib:ie+1) :: uf
      real, intent(in),    dimension(jb:je) :: vh
      real, intent(in),    dimension(ib:ie) :: arh1,arh2
      real, intent(in),    dimension(ib:ie+1) :: arf1,arf2
      real, intent(in),    dimension(ib:ie,jb:je,kb:ke) :: mh
      real, intent(in),    dimension(kb:ke+1) :: rdsf
      real, intent(in),    dimension(itb:ite,jtb:jte) :: gzu
      real, intent(in),    dimension(ib:ie,jb:je,kb:ke) :: rho0,rr0
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: dum1,dum2,dum3
      real, intent(in),    dimension(ib:ie+1,jb:je,kb:ke) :: rru
      real, intent(in),    dimension(ib:ie,jb:je+1,kb:ke) :: rrv
      real, intent(in),    dimension(ib:ie,jb:je,kb:ke+1) :: rrw
      real, intent(in),    dimension(ib:ie+1,jb:je,kb:ke) :: u3d
      real, intent(inout), dimension(ib:ie+1,jb:je,kb:ke) :: uten

      integer :: i,j,k,i2
      real :: ubar,vbar,wbar

      uten = 0.0
      dum1 = 0.0
      dum2 = 0.0
      dum3 = 0.0

      !---

    hadvu:  IF(hadvordrv.eq.5)THEN

      IF(axisymm.eq.0)THEN

        ! Cartesian grid:
!$omp parallel do default(shared)  &
!$omp private(i,j,k,ubar,vbar)
        do k=1,nk
          do j=1,nj
          do i=0,ni+1
            ubar = 0.5*(rru(i,j,k)+rru(i+1,j,k))
            dum1(i,j,k) = ubar*( -sign(1.0,ubar)                   &
                             *( 10.0*(u3d(i+1,j,k)-u3d(i  ,j,k))   &
                                -5.0*(u3d(i+2,j,k)-u3d(i-1,j,k))   &
                                    +(u3d(i+3,j,k)-u3d(i-2,j,k)) ) )*onedsixty
          enddo
          enddo
          do j=1,nj+1
          do i=1,ni+1
            vbar = 0.5*(rrv(i,j,k)+rrv(i-1,j,k))
            dum2(i,j,k) = vbar*( -sign(1.0,vbar)                   &
                             *( 10.0*(u3d(i,j  ,k)-u3d(i,j-1,k))   &
                                -5.0*(u3d(i,j+1,k)-u3d(i,j-2,k))   &
                                    +(u3d(i,j+2,k)-u3d(i,j-3,k)) ) )*onedsixty
          enddo
          enddo
        enddo

      ELSE

        ! axisymmetric grid:
!$omp parallel do default(shared)  &
!$omp private(i,j,k,ubar,vbar)
        do k=1,nk
          do j=1,nj
            do i=2,ni+1
              ubar = 0.5*(arh1(i)*rru(i,j,k)+arh2(i)*rru(i+1,j,k))
              dum1(i,j,k) = ubar*( -sign(1.0,ubar)                   &
                               *( 10.0*(u3d(i+1,j,k)-u3d(i  ,j,k))   &
                                  -5.0*(u3d(i+2,j,k)-u3d(i-1,j,k))   &
                                      +(u3d(i+3,j,k)-u3d(i-2,j,k)) ) )*onedsixty
            enddo
            i = 2
            ubar = 0.5*(arh1(i)*rru(i,j,k)+arh2(i)*rru(i+1,j,k))
            if(ubar.gt.0.0)then
              dum1(i,j,k) = ubar*( -sign(1.0,ubar)                &
                             *( 3.0*(u3d(i+1,j,k)-u3d(i  ,j,k))   &
                                   -(u3d(i+2,j,k)-u3d(i-1,j,k)) ) )*onedtwelve
            endif
            i = 1
            ubar = 0.5*(arh1(i)*rru(i,j,k)+arh2(i)*rru(i+1,j,k))
            if(ubar.lt.0.0)then
              dum1(i,j,k) = ubar*( -sign(1.0,ubar)                &
                             *( 3.0*(u3d(i+1,j,k)-u3d(i  ,j,k))   &
                                   -(u3d(i+2,j,k)-u3d(i-1,j,k)) ) )*onedtwelve
            endif
          enddo
        enddo

      ENDIF

    ENDIF  hadvu

      !---

    vadvu:  IF(vadvordrv.eq.5)THEN

      IF(axisymm.eq.0)THEN

!$omp parallel do default(shared)  &
!$omp private(i,j,k,wbar)
        do j=1,nj
          do k=3,nk-1
          do i=1,ni+1
            wbar = 0.5*(rrw(i,j,k)+rrw(i-1,j,k))
            dum3(i,j,k) = wbar*( -sign(1.0,wbar)                   &
                             *( 10.0*(u3d(i,j,k  )-u3d(i,j,k-1))   &
                                -5.0*(u3d(i,j,k+1)-u3d(i,j,k-2))   &
                                    +(u3d(i,j,k+2)-u3d(i,j,k-3)) ) )*onedsixty
          enddo
          enddo
          k = 3
          do i=1,ni+1
            wbar = 0.5*(rrw(i,j,k)+rrw(i-1,j,k))
            if(wbar.gt.0.0)then
              dum3(i,j,k) = wbar*( -sign(1.0,wbar)                &
                             *( 3.0*(u3d(i,j,k  )-u3d(i,j,k-1))   &
                                   -(u3d(i,j,k+1)-u3d(i,j,k-2)) ) )*onedtwelve
            endif
          enddo
          k = nk-1
          do i=1,ni+1
            wbar = 0.5*(rrw(i,j,k)+rrw(i-1,j,k))
            if(wbar.lt.0.0)then
              dum3(i,j,k) = wbar*( -sign(1.0,wbar)                &
                             *( 3.0*(u3d(i,j,k  )-u3d(i,j,k-1))   &
                                   -(u3d(i,j,k+1)-u3d(i,j,k-2)) ) )*onedtwelve
            endif
          enddo
          k = 2
          do i=1,ni+1
            wbar = 0.5*(rrw(i,j,k)+rrw(i-1,j,k))
            if(wbar.lt.0.0)then
              dum3(i,j,k) = wbar*( -sign(1.0,wbar)                &
                             *( 3.0*(u3d(i,j,k  )-u3d(i,j,k-1))   &
                                   -(u3d(i,j,k+1)-u3d(i,j,k-2)) ) )*onedtwelve
            endif
          enddo
          k = nk
          do i=1,ni+1
            wbar = 0.5*(rrw(i,j,k)+rrw(i-1,j,k))
            if(wbar.gt.0.0)then
              dum3(i,j,k) = wbar*( -sign(1.0,wbar)                &
                             *( 3.0*(u3d(i,j,k  )-u3d(i,j,k-1))   &
                                   -(u3d(i,j,k+1)-u3d(i,j,k-2)) ) )*onedtwelve
            endif
          enddo
        enddo

      ELSE

        if(ibe.eq.1)then
          i2=ni+1-1
        else
          i2=ni+1
        endif
        IF(ebc.eq.3.or.ebc.eq.4) i2 = ni

!$omp parallel do default(shared)  &
!$omp private(i,j,k,wbar)
        do j=1,nj
          do k=3,nk-1
          do i=2,i2
            wbar = 0.5*(arf2(i)*rrw(i,j,k)+arf1(i)*rrw(i-1,j,k))
            dum3(i,j,k) = wbar*( -sign(1.0,wbar)                   &
                             *( 10.0*(u3d(i,j,k  )-u3d(i,j,k-1))   &
                                -5.0*(u3d(i,j,k+1)-u3d(i,j,k-2))   &
                                    +(u3d(i,j,k+2)-u3d(i,j,k-3)) ) )*onedsixty
          enddo
          enddo
          k = 3
          do i=2,i2
            wbar = 0.5*(arf2(i)*rrw(i,j,k)+arf1(i)*rrw(i-1,j,k))
            if(wbar.gt.0.0)then
              dum3(i,j,k) = wbar*( -sign(1.0,wbar)                &
                             *( 3.0*(u3d(i,j,k  )-u3d(i,j,k-1))   &
                                   -(u3d(i,j,k+1)-u3d(i,j,k-2)) ) )*onedtwelve
            endif
          enddo
          k = nk-1
          do i=2,i2
            wbar = 0.5*(arf2(i)*rrw(i,j,k)+arf1(i)*rrw(i-1,j,k))
            if(wbar.lt.0.0)then
              dum3(i,j,k) = wbar*( -sign(1.0,wbar)                &
                             *( 3.0*(u3d(i,j,k  )-u3d(i,j,k-1))   &
                                   -(u3d(i,j,k+1)-u3d(i,j,k-2)) ) )*onedtwelve
            endif
          enddo
          k = 2
          do i=2,i2
            wbar = 0.5*(arf2(i)*rrw(i,j,k)+arf1(i)*rrw(i-1,j,k))
            if(wbar.lt.0.0)then
              dum3(i,j,k) = wbar*( -sign(1.0,wbar)                &
                             *( 3.0*(u3d(i,j,k  )-u3d(i,j,k-1))   &
                                   -(u3d(i,j,k+1)-u3d(i,j,k-2)) ) )*onedtwelve
            endif
          enddo
          k = nk
          do i=2,i2
            wbar = 0.5*(arf2(i)*rrw(i,j,k)+arf1(i)*rrw(i-1,j,k))
            if(wbar.gt.0.0)then
              dum3(i,j,k) = wbar*( -sign(1.0,wbar)                &
                             *( 3.0*(u3d(i,j,k  )-u3d(i,j,k-1))   &
                                   -(u3d(i,j,k+1)-u3d(i,j,k-2)) ) )*onedtwelve
            endif
          enddo
        enddo

      ENDIF

    ENDIF  vadvu

      !---

      IF(.not.terrain_flag)THEN

        IF(axisymm.eq.0)THEN

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni+1
            uten(i,j,k) = ( -(dum1(i,j,k)-dum1(i-1,j,k))*rdx*uf(i)      &
                            -(dum2(i,j+1,k)-dum2(i,j,k))*rdy*vh(j)      &
                            -(dum3(i,j,k+1)-dum3(i,j,k))*rdz*mh(1,1,k)  &
                          )*rr0(1,1,k)
          enddo
          enddo
          enddo

        ELSE

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=2,ni+1
            uten(i,j,k) = ( -(arf2(i)*dum1(i,j,k)-arf1(i)*dum1(i-1,j,k))*rdx*uf(i)  &
                            -(dum3(i,j,k+1)-dum3(i,j,k))*rdz*mh(1,1,k)  &
                          )*rr0(1,1,k)
          enddo
          IF(ebc.eq.3.or.ebc.eq.4)THEN
            uten(ni+1,j,k)=0.0
          ENDIF
          enddo
          enddo

        ENDIF

      ELSE

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk
        do j=1,nj
        do i=1,ni+1
          uten(i,j,k) = ( -(dum1(i,j,k)-dum1(i-1,j,k))*rdx*uf(i)      &
                          -(dum2(i,j+1,k)-dum2(i,j,k))*rdy*vh(j)      &
                          -(dum3(i,j,k+1)-dum3(i,j,k))*rdsf(k)        &
                        )*gzu(i,j)/(0.5*(rho0(i-1,j,k)+rho0(i,j,k)))
        enddo
        enddo
        enddo

      ENDIF

      if(timestats.ge.1) time_misc=time_misc+mytime()

      return
      end


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine impldiffv(uh,vf,arh1,arh2,mh,rdsf,gzv,rho0,rr0,dum1,dum2,dum3,rru,rrv,rrw,v3d,vten)
      implicit none

      include 'input.incl'
      include 'constants.incl'
      include 'timestat.incl'

      real, intent(in),    dimension(ib:ie) :: uh
      real, intent(in),    dimension(jb:je+1) :: vf
      real, intent(in),    dimension(ib:ie) :: arh1,arh2
      real, intent(in),    dimension(ib:ie,jb:je,kb:ke) :: mh
      real, intent(in),    dimension(kb:ke+1) :: rdsf
      real, intent(in),    dimension(itb:ite,jtb:jte) :: gzv
      real, intent(in),    dimension(ib:ie,jb:je,kb:ke) :: rho0,rr0
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: dum1,dum2,dum3
      real, intent(in),    dimension(ib:ie+1,jb:je,kb:ke) :: rru
      real, intent(in),    dimension(ib:ie,jb:je+1,kb:ke) :: rrv
      real, intent(in),    dimension(ib:ie,jb:je,kb:ke+1) :: rrw
      real, intent(in),    dimension(ib:ie,jb:je+1,kb:ke) :: v3d
      real, intent(inout), dimension(ib:ie,jb:je+1,kb:ke) :: vten

      integer :: i,j,k
      real :: ubar,vbar,wbar

      vten = 0.0
      dum1 = 0.0
      dum2 = 0.0
      dum3 = 0.0

      !---

    hadvv:  IF(hadvordrv.eq.5)THEN

      IF(axisymm.eq.0)THEN

!$omp parallel do default(shared)  &
!$omp private(i,j,k,ubar,vbar)
        do k=1,nk
          do j=1,nj+1
          do i=1,ni+1
            ubar = 0.5*(rru(i,j,k)+rru(i,j-1,k))
            dum1(i,j,k) = ubar*( -sign(1.0,ubar)                   &
                             *( 10.0*(v3d(i  ,j,k)-v3d(i-1,j,k))   &
                                -5.0*(v3d(i+1,j,k)-v3d(i-2,j,k))   &
                                    +(v3d(i+2,j,k)-v3d(i-3,j,k)) ) )*onedsixty
          enddo
          enddo
          do j=0,nj+1
          do i=1,ni
            vbar = 0.5*(rrv(i,j,k)+rrv(i,j+1,k))
            dum2(i,j,k) = vbar*( -sign(1.0,vbar)                   &
                             *( 10.0*(v3d(i,j+1,k)-v3d(i,j  ,k))   &
                                -5.0*(v3d(i,j+2,k)-v3d(i,j-1,k))   &
                                    +(v3d(i,j+3,k)-v3d(i,j-2,k)) ) )*onedsixty
          enddo
          enddo
        enddo

      ELSE

!$omp parallel do default(shared)  &
!$omp private(i,j,k,ubar,vbar)
        do k=1,nk
          do j=1,nj
            do i=3,ni+1
              ubar = rru(i,j,k)
              dum1(i,j,k) = ubar*( -sign(1.0,ubar)                   &
                               *( 10.0*(v3d(i  ,j,k)-v3d(i-1,j,k))   &
                                  -5.0*(v3d(i+1,j,k)-v3d(i-2,j,k))   &
                                      +(v3d(i+2,j,k)-v3d(i-3,j,k)) ) )*onedsixty
            enddo
            i = 3
            ubar = rru(i,j,k)
            if(ubar.gt.0.0)then
              dum1(i,j,k) = ubar*( -sign(1.0,ubar)                &
                             *( 3.0*(v3d(i  ,j,k)-v3d(i-1,j,k))   &
                                   -(v3d(i+1,j,k)-v3d(i-2,j,k)) ) )*onedtwelve
            endif
            i = 2
            ubar = rru(i,j,k)
            if(ubar.lt.0.0)then
              dum1(i,j,k) = ubar*( -sign(1.0,ubar)                &
                             *( 3.0*(v3d(i  ,j,k)-v3d(i-1,j,k))   &
                                   -(v3d(i+1,j,k)-v3d(i-2,j,k)) ) )*onedtwelve
            endif
          enddo
        enddo

      ENDIF

    ENDIF  hadvv

      !---

    vadvv:  IF(vadvordrv.eq.5)THEN

!$omp parallel do default(shared)  &
!$omp private(i,j,k,wbar)
        do j=1,nj+1
          do k=3,nk-1
          do i=1,ni
            wbar = 0.5*(rrw(i,j,k)+rrw(i,j-1,k))
            dum3(i,j,k) = wbar*( -sign(1.0,wbar)                   &
                             *( 10.0*(v3d(i,j,k  )-v3d(i,j,k-1))   &
                                -5.0*(v3d(i,j,k+1)-v3d(i,j,k-2))   &
                                    +(v3d(i,j,k+2)-v3d(i,j,k-3)) ) )*onedsixty
          enddo
          enddo
          k = 3
          do i=1,ni
            wbar = 0.5*(rrw(i,j,k)+rrw(i,j-1,k))
            if(wbar.gt.0.0)then
              dum3(i,j,k) = wbar*( -sign(1.0,wbar)                &
                             *( 3.0*(v3d(i,j,k  )-v3d(i,j,k-1))   &
                                   -(v3d(i,j,k+1)-v3d(i,j,k-2)) ) )*onedtwelve
            endif
          enddo
          k = nk-1
          do i=1,ni
            wbar = 0.5*(rrw(i,j,k)+rrw(i,j-1,k))
            if(wbar.lt.0.0)then
              dum3(i,j,k) = wbar*( -sign(1.0,wbar)                &
                             *( 3.0*(v3d(i,j,k  )-v3d(i,j,k-1))   &
                                   -(v3d(i,j,k+1)-v3d(i,j,k-2)) ) )*onedtwelve
            endif
          enddo
          k = 2
          do i=1,ni
            wbar = 0.5*(rrw(i,j,k)+rrw(i,j-1,k))
            if(wbar.lt.0.0)then
              dum3(i,j,k) = wbar*( -sign(1.0,wbar)                &
                             *( 3.0*(v3d(i,j,k  )-v3d(i,j,k-1))   &
                                   -(v3d(i,j,k+1)-v3d(i,j,k-2)) ) )*onedtwelve
            endif
          enddo
          k = nk
          do i=1,ni
            wbar = 0.5*(rrw(i,j,k)+rrw(i,j-1,k))
            if(wbar.gt.0.0)then
              dum3(i,j,k) = wbar*( -sign(1.0,wbar)                &
                             *( 3.0*(v3d(i,j,k  )-v3d(i,j,k-1))   &
                                   -(v3d(i,j,k+1)-v3d(i,j,k-2)) ) )*onedtwelve
            endif
          enddo
        enddo

    ENDIF  vadvv

      !---

      IF(.not.terrain_flag)THEN

        IF(axisymm.eq.0)THEN

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj+1
          do i=1,ni
            vten(i,j,k) = ( -(dum1(i+1,j,k)-dum1(i,j,k))*rdx*uh(i)      &
                            -(dum2(i,j,k)-dum2(i,j-1,k))*rdy*vf(j)      &
                            -(dum3(i,j,k+1)-dum3(i,j,k))*rdz*mh(1,1,k)  &
                          )*rr0(1,1,k)
          enddo
          enddo
          enddo

        ELSE

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            vten(i,j,k) = ( -(arh2(i)*dum1(i+1,j,k)-arh1(i)*dum1(i,j,k))*rdx*uh(i)  &
                            -(dum3(i,j,k+1)-dum3(i,j,k))*rdz*mh(1,1,k)  &
                          )*rr0(1,1,k)
          enddo
          enddo
          enddo

        ENDIF

      ELSE

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk
        do j=1,nj+1
        do i=1,ni
          vten(i,j,k) = ( -(dum1(i+1,j,k)-dum1(i,j,k))*rdx*uh(i)      &
                          -(dum2(i,j,k)-dum2(i,j-1,k))*rdy*vf(j)      &
                          -(dum3(i,j,k+1)-dum3(i,j,k))*rdsf(k)        &
                        )*gzv(i,j)/(0.5*(rho0(i,j-1,k)+rho0(i,j,k)))
        enddo
        enddo
        enddo

      ENDIF

      if(timestats.ge.1) time_misc=time_misc+mytime()

      return
      end


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine impldiffw(uh,vh,arh1,arh2,mf,gz,rds,rrf0,dum1,dum2,dum3,rru,rrv,rrw,w3d,wten,c1,c2)
      implicit none

      include 'input.incl'
      include 'constants.incl'
      include 'timestat.incl'

      real, intent(in),    dimension(ib:ie) :: uh
      real, intent(in),    dimension(jb:je) :: vh
      real, intent(in),    dimension(ib:ie) :: arh1,arh2
      real, intent(in),    dimension(ib:ie,jb:je,kb:ke+1) :: mf
      real, intent(in),    dimension(kb:ke) :: rds
      real, intent(in),    dimension(itb:ite,jtb:jte) :: gz
      real, intent(in),    dimension(ib:ie,jb:je,kb:ke) :: rrf0
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: dum1,dum2,dum3
      real, intent(in),    dimension(ib:ie+1,jb:je,kb:ke) :: rru
      real, intent(in),    dimension(ib:ie,jb:je+1,kb:ke) :: rrv
      real, intent(in),    dimension(ib:ie,jb:je,kb:ke+1) :: rrw
      real, intent(in),    dimension(ib:ie,jb:je,kb:ke+1) :: w3d
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke+1) :: wten
      real, intent(in),    dimension(ib:ie,jb:je,kb:ke) :: c1,c2

      integer :: i,j,k
      real :: ubar,vbar,wbar,cc1,cc2

      wten = 0.0
      dum1 = 0.0
      dum2 = 0.0
      dum3 = 0.0

      !---

    hadvw:  IF(hadvordrv.eq.5)THEN

      IF(axisymm.eq.0)THEN

!$omp parallel do default(shared)  &
!$omp private(i,j,k,cc1,cc2,ubar,vbar)
        do k=1,nk
          do j=1,nj+1
          do i=1,ni+1
            cc2 = 0.5*(c2(i-1,j,k)+c2(i,j,k))
            cc1 = 1.0-cc2
            ubar = cc2*rru(i,j,k)+cc1*rru(i,j,k-1)
            dum1(i,j,k) = ubar*( -sign(1.0,ubar)                   &
                             *( 10.0*(w3d(i  ,j,k)-w3d(i-1,j,k))   &
                                -5.0*(w3d(i+1,j,k)-w3d(i-2,j,k))   &
                                    +(w3d(i+2,j,k)-w3d(i-3,j,k)) ) )*onedsixty
          enddo
          enddo
          do j=1,nj+1
          do i=1,ni+1
            cc2 = 0.5*(c2(i,j-1,k)+c2(i,j,k))
            cc1 = 1.0-cc2
            vbar = cc2*rrv(i,j,k)+cc1*rrv(i,j,k-1)
            dum2(i,j,k) = vbar*( -sign(1.0,vbar)                   &
                             *( 10.0*(w3d(i,j  ,k)-w3d(i,j-1,k))   &
                                -5.0*(w3d(i,j+1,k)-w3d(i,j-2,k))   &
                                    +(w3d(i,j+2,k)-w3d(i,j-3,k)) ) )*onedsixty
          enddo
          enddo
        enddo

      ELSE

!$omp parallel do default(shared)  &
!$omp private(i,j,k,ubar,vbar)
        do k=1,nk
          do j=1,nj
            do i=3,ni+1
              ubar = c2(1,1,k)*rru(i,j,k)+c1(1,1,k)*rru(i,j,k-1)
              dum1(i,j,k) = ubar*( -sign(1.0,ubar)                   &
                               *( 10.0*(w3d(i  ,j,k)-w3d(i-1,j,k))   &
                                  -5.0*(w3d(i+1,j,k)-w3d(i-2,j,k))   &
                                      +(w3d(i+2,j,k)-w3d(i-3,j,k)) ) )*onedsixty
            enddo
            i = 3
            ubar = c2(1,1,k)*rru(i,j,k)+c1(1,1,k)*rru(i,j,k-1)
            if(ubar.gt.0.0)then
              dum1(i,j,k) = ubar*( -sign(1.0,ubar)                &
                             *( 3.0*(w3d(i  ,j,k)-w3d(i-1,j,k))   &
                                   -(w3d(i+1,j,k)-w3d(i-2,j,k)) ) )*onedtwelve
            endif
            i = 2
            ubar = c2(1,1,k)*rru(i,j,k)+c1(1,1,k)*rru(i,j,k-1)
            if(ubar.lt.0.0)then
              dum1(i,j,k) = ubar*( -sign(1.0,ubar)                &
                             *( 3.0*(w3d(i  ,j,k)-w3d(i-1,j,k))   &
                                   -(w3d(i+1,j,k)-w3d(i-2,j,k)) ) )*onedtwelve
            endif
          enddo
        enddo

      ENDIF

    ENDIF  hadvw

      !---

    vadvw:  IF(vadvordrv.eq.5)THEN

!$omp parallel do default(shared)  &
!$omp private(i,j,k,wbar)
        do j=1,nj+1
          do k=2,nk-1
          do i=1,ni
            wbar = 0.5*(rrw(i,j,k)+rrw(i,j,k+1))
            dum3(i,j,k) = wbar*( -sign(1.0,wbar)                   &
                             *( 10.0*(w3d(i,j,k+1)-w3d(i,j,k  ))   &
                                -5.0*(w3d(i,j,k+2)-w3d(i,j,k-1))   &
                                    +(w3d(i,j,k+3)-w3d(i,j,k-2)) ) )*onedsixty
          enddo
          enddo
          k = 2
          do i=1,ni
            wbar = 0.5*(rrw(i,j,k)+rrw(i,j,k+1))
            if(wbar.gt.0.0)then
              dum3(i,j,k) = wbar*( -sign(1.0,wbar)                &
                             *( 3.0*(w3d(i,j,k+1)-w3d(i,j,k  ))   &
                                   -(w3d(i,j,k+2)-w3d(i,j,k-1)) ) )*onedtwelve
            endif
          enddo
          k = nk-1
          do i=1,ni
            wbar = 0.5*(rrw(i,j,k)+rrw(i,j,k+1))
            if(wbar.lt.0.0)then
              dum3(i,j,k) = wbar*( -sign(1.0,wbar)                &
                             *( 3.0*(w3d(i,j,k+1)-w3d(i,j,k  ))   &
                                   -(w3d(i,j,k+2)-w3d(i,j,k-1)) ) )*onedtwelve
            endif
          enddo
          k = 1
          do i=1,ni
            wbar = 0.5*(rrw(i,j,k)+rrw(i,j,k+1))
            if(wbar.lt.0.0)then
              dum3(i,j,k) = wbar*( -sign(1.0,wbar)                &
                             *( 3.0*(w3d(i,j,k+1)-w3d(i,j,k  ))   &
                                   -(w3d(i,j,k+2)-w3d(i,j,k-1)) ) )*onedtwelve
            endif
          enddo
          k = nk
          do i=1,ni
            wbar = 0.5*(rrw(i,j,k)+rrw(i,j,k+1))
            if(wbar.gt.0.0)then
              dum3(i,j,k) = wbar*( -sign(1.0,wbar)                &
                             *( 3.0*(w3d(i,j,k+1)-w3d(i,j,k  ))   &
                                   -(w3d(i,j,k+2)-w3d(i,j,k-1)) ) )*onedtwelve
            endif
          enddo
        enddo

    ENDIF  vadvw

      !---

      IF(.not.terrain_flag)THEN

        IF(axisymm.eq.0)THEN

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=2,nk
          do j=1,nj
          do i=1,ni
            wten(i,j,k) = ( -(dum1(i+1,j,k)-dum1(i,j,k))*rdx*uh(i)      &
                            -(dum2(i,j+1,k)-dum2(i,j,k))*rdy*vh(j)      &
                            -(dum3(i,j,k)-dum3(i,j,k-1))*rdz*mf(1,1,k)  &
                          )*rrf0(1,1,k)
          enddo
          enddo
          enddo

        ELSE

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=2,nk
          do j=1,nj
          do i=1,ni
            wten(i,j,k) = ( -(arh2(i)*dum1(i+1,j,k)-arh1(i)*dum1(i,j,k))*rdx*uh(i)  &
                            -(dum3(i,j,k)-dum3(i,j,k-1))*rdz*mf(1,1,k)  &
                          )*rrf0(1,1,k)
          enddo
          enddo
          enddo

        ENDIF

      ELSE

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=2,nk
        do j=1,nj
        do i=1,ni
          wten(i,j,k) = ( -(dum1(i+1,j,k)-dum1(i,j,k))*rdx*uh(i)      &
                          -(dum2(i,j+1,k)-dum2(i,j,k))*rdy*vh(j)      &
                          -(dum3(i,j,k)-dum3(i,j,k-1))*rds(k)         &
                        )*rrf0(i,j,k)*gz(i,j)
        enddo
        enddo
        enddo

      ENDIF

      if(timestats.ge.1) time_misc=time_misc+mytime()

      return
      end


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine calcuh(uf,vf,zh,zf,ua,va,wa,uh,zeta,dum1,dum2, &
                        zs,rgzu,rgzv,rds,sigma,rdsf,sigmaf)
      implicit none

      ! Subroutine to calculate vertically integrated updraft helicity
      ! Reference:  Kain et al, 2008, WAF, p 931

      include 'input.incl'
      include 'timestat.incl'

      ! note:  need zh,zf Above Ground Level

      real, intent(in), dimension(ib:ie+1) :: uf
      real, intent(in), dimension(jb:je+1) :: vf
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: zh
      real, intent(in), dimension(ib:ie,jb:je,kb:ke+1) :: zf
      real, intent(in), dimension(ib:ie+1,jb:je,kb:ke) :: ua
      real, intent(in), dimension(ib:ie,jb:je+1,kb:ke) :: va
      real, intent(in), dimension(ib:ie,jb:je,kb:ke+1) :: wa
      real, intent(inout), dimension(ib:ie,jb:je) :: uh
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: zeta,dum1,dum2
      real, intent(in), dimension(ib:ie,jb:je) :: zs
      real, intent(in), dimension(itb:ite,jtb:jte) :: rgzu,rgzv
      real, intent(in), dimension(kb:ke) :: rds,sigma
      real, intent(in), dimension(kb:ke+1) :: rdsf,sigmaf

      real, parameter :: zz0 = 2000.0     ! bottom of integration layer (m AGL)
      real, parameter :: zzt = 5000.0     ! top of integration layer (m AGL)

      integer :: i,j,k
      real :: r1,r2
      real :: wbar,zbar

  IF(.not.terrain_flag)THEN

    ! Cartesian grid, without terrain:

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
    DO k=1,nk
    DO j=1,nj+1
    DO i=1,ni+1
      zeta(i,j,k) = (va(i,j,k)-va(i-1,j,k))*rdx*uf(i)   &
                   -(ua(i,j,k)-ua(i,j-1,k))*rdy*vf(j)
    ENDDO
    ENDDO
    ENDDO

  ELSE

    ! Cartesian grid, with terrain:

        ! dum1 stores u at w-pts:
        ! dum2 stores v at w-pts:
!$omp parallel do default(shared)   &
!$omp private(i,j,k,r1,r2)
        do j=0,nj+2
          ! lowest model level:
          do i=0,ni+2
            dum1(i,j,1) = cgs1*ua(i,j,1)+cgs2*ua(i,j,2)+cgs3*ua(i,j,3)
            dum2(i,j,1) = cgs1*va(i,j,1)+cgs2*va(i,j,2)+cgs3*va(i,j,3)
          enddo

          ! upper-most model level:
          do i=0,ni+2
            dum1(i,j,nk+1) = cgt1*ua(i,j,nk)+cgt2*ua(i,j,nk-1)+cgt3*ua(i,j,nk-2)
            dum2(i,j,nk+1) = cgt1*va(i,j,nk)+cgt2*va(i,j,nk-1)+cgt3*va(i,j,nk-2)
          enddo

          ! interior:
          do k=2,nk
          r2 = (sigmaf(k)-sigma(k-1))*rds(k)
          r1 = 1.0-r2
          do i=0,ni+2
            dum1(i,j,k) = r1*ua(i,j,k-1)+r2*ua(i,j,k)
            dum2(i,j,k) = r1*va(i,j,k-1)+r2*va(i,j,k)
          enddo
          enddo
        enddo
!$omp parallel do default(shared)  &
!$omp private(i,j,k,r1)
        do k=1,nk
          do j=1,nj+1
          do i=1,ni+1
            r1 = zt/(zt-0.25*((zs(i-1,j-1)+zs(i,j))+(zs(i-1,j)+zs(i,j-1))))
            zeta(i,j,k)=( r1*(va(i,j,k)*rgzv(i,j)-va(i-1,j,k)*rgzv(i-1,j))*rdx*uf(i)  &
                         +0.5*( (zt-sigmaf(k+1))*(dum2(i-1,j,k+1)+dum2(i,j,k+1))      &
                               -(zt-sigmaf(k  ))*(dum2(i-1,j,k  )+dum2(i,j,k  ))      &
                              )*rdsf(k)*r1*(rgzv(i,j)-rgzv(i-1,j))*rdx*uf(i) )        &
                       -( r1*(ua(i,j,k)*rgzu(i,j)-ua(i,j-1,k)*rgzu(i,j-1))*rdy*vf(j)  &
                         +0.5*( (zt-sigmaf(k+1))*(dum1(i,j-1,k+1)+dum1(i,j,k+1))      &
                               -(zt-sigmaf(k  ))*(dum1(i,j-1,k  )+dum1(i,j,k  ))      &
                              )*rdsf(k)*r1*(rgzu(i,j)-rgzu(i,j-1))*rdy*vf(j) )
          enddo
          enddo
        enddo

  ENDIF

!$omp parallel do default(shared)  &
!$omp private(i,j,k,wbar,zbar)
    DO j=1,nj
    DO i=1,ni
      uh(i,j) = 0.0
      DO k=1,nk
        IF( zh(i,j,k).ge.zz0 .and. zh(i,j,k).le.zzt )THEN
          ! note:  only consider cyclonically rotating updrafts
          !        (so, w and zeta must both be positive)
          wbar = max( 0.0 , 0.5*(wa(i,j,k)+wa(i,j,k+1)) )
          zbar = max( 0.0 , 0.25*(zeta(i,j,k)+zeta(i+1,j,k)   &
                                 +zeta(i,j+1,k)+zeta(i+1,j+1,k)) )
          uh(i,j) = uh(i,j) + (min(zf(i,j,k+1),zzt)-max(zf(i,j,k),zz0))*wbar*zbar
        ENDIF
      ENDDO
    ENDDO
    ENDDO

      return
      end subroutine calcuh


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine calcvort(xh,xf,uf,vf,zh,mh,zf,mf,zs,gz,gzu,gzv,rgz,rgzu,rgzv,gxu,gyv,rds,sigma,rdsf,sigmaf,  &
                          ua,va,wa,xvort,yvort,zvort,tem ,dum1,dum2,pv  ,th  ,th0,tha,rr,  &
                          ust,znt,u1,v1,s1)
      implicit none

      ! Subroutine to calculate 3 components of vorticity
      ! at scalar points.

      include 'input.incl'
      include 'constants.incl'
      include 'timestat.incl'

      real, intent(in), dimension(ib:ie) :: xh
      real, intent(in), dimension(ib:ie+1) :: xf,uf
      real, intent(in), dimension(jb:je+1) :: vf
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: zh,mh
      real, intent(in), dimension(ib:ie,jb:je,kb:ke+1) :: zf,mf
      real, intent(in), dimension(ib:ie,jb:je) :: zs
      real, intent(in), dimension(itb:ite,jtb:jte) :: gz,gzu,gzv,rgz,rgzu,rgzv
      real, intent(in), dimension(itb:ite,jtb:jte,ktb:kte) :: gxu,gyv
      real, intent(in), dimension(kb:ke) :: rds,sigma
      real, intent(in), dimension(kb:ke+1) :: rdsf,sigmaf
      real, intent(in), dimension(ib:ie+1,jb:je,kb:ke) :: ua
      real, intent(in), dimension(ib:ie,jb:je+1,kb:ke) :: va
      real, intent(in), dimension(ib:ie,jb:je,kb:ke+1) :: wa
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: xvort,yvort,zvort,tem,dum1,dum2,pv,th
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: th0,tha,rr
      real, intent(in), dimension(ib:ie,jb:je) :: ust,znt,u1,v1,s1

      integer :: i,j,k
      real :: r1,r2

!-----------------------------------------------------------------------

      IF( output_pv.eq.1 )THEN
        do k=1,nk
        do j=1,nj
        do i=1,ni
          pv(i,j,k)=0.0
        enddo
        enddo
        enddo
      ENDIF

    IF( terrain_flag )THEN
      ! dum1 stores w at scalar pts
      ! dum2 stores theta at w pts
!$omp parallel do default(shared)   &
!$omp private(i,j,k)
      do j=0,nj+1
        do k=1,nk
        do i=0,ni+1
          dum1(i,j,k)=0.5*(wa(i,j,k)+wa(i,j,k+1))
          th(i,j,k)=th0(i,j,k)+tha(i,j,k)
        enddo
        enddo
        ! lowest model level:
        do i=0,ni+1
          dum2(i,j,1) = cgs1*th(i,j,1)+cgs2*th(i,j,2)+cgs3*th(i,j,3)
        enddo
        ! upper-most model level:
        do i=0,ni+1
          dum2(i,j,nk+1) = cgt1*th(i,j,nk)+cgt2*th(i,j,nk-1)+cgt3*th(i,j,nk-2)
        enddo
        ! interior:
        do k=2,nk
        r2 = (sigmaf(k)-sigma(k-1))*rds(k)
        r1 = 1.0-r2
        do i=0,ni+1
          dum2(i,j,k) = r1*th(i,j,k-1)+r2*th(i,j,k)
        enddo
        enddo
      enddo
    ENDIF

!-----------------------------------------------------------------------
! x-vort:

  tem=0.0
  if(axisymm.eq.0)then
    IF(.not.terrain_flag)THEN
      !cccccccccccccccccccccccccccccccccccccc
      ! Cartesian grid, without terrain:
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      do k=2,nk
      do j=1,nj+1
      do i=1,ni
        tem(i,j,k) = (wa(i,j,k)-wa(i,j-1,k))*rdy*vf(j)   &
                    -(va(i,j,k)-va(i,j,k-1))*rdz*0.5*(mf(i,j-1,k)+mf(i,j,k))
      enddo
      enddo
      enddo
      IF( bbc.eq.1 )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do j=1,nj+1
        do i=1,ni
          tem(i,j,1)=tem(i,j,2)
        enddo
        enddo
      ELSEIF( bbc.eq.2 )THEN
      if( imove.eq.0 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do j=1,nj+1
        do i=1,ni
          tem(i,j,1)=-2.0*va(i,j,1)*rdz*0.5*(mf(i,j-1,1)+mf(i,j,1))
        enddo
        enddo
      else
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do j=1,nj+1
        do i=1,ni
          tem(i,j,1)=-2.0*(va(i,j,1)+vmove)*rdz*0.5*(mf(i,j-1,1)+mf(i,j,1))
        enddo
        enddo
      endif
      ENDIF
      IF( tbc.eq.1 )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do j=1,nj+1
        do i=1,ni
          tem(i,j,nk+1)=tem(i,j,nk)
        enddo
        enddo
      ELSEIF( tbc.eq.2 )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do j=1,nj+1
        do i=1,ni
          tem(i,j,nk+1)=2.0*va(i,j,nk)*rdz*0.5*(mf(i,j-1,nk+1)+mf(i,j,nk+1))
        enddo
        enddo
      ENDIF
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      do k=1,nk
      do j=1,nj
      do i=1,ni
        xvort(i,j,k) = 0.25*(tem(i,j,k)+tem(i,j+1,k)+tem(i,j,k+1)+tem(i,j+1,k+1))
      enddo
      enddo
      enddo
      !cccccccccccccccccccccccccccccccccccccc
    getpv11: IF( output_pv.eq.1 )THEN
      ! here, zvort array stores d(th)/dx
      do k=1,nk
      do j=1,nj
      do i=1,ni+1
        zvort(i,j,k) = (th(i,j,k)-th(i-1,j,k))*rdx*uf(i)
      enddo
      enddo
      enddo
      ! pv1:
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      do k=1,nk
      do j=1,nj
      do i=1,ni
        pv(i,j,k)=pv(i,j,k)+xvort(i,j,k)*0.5*( zvort(i,j,k)+zvort(i+1,j,k) )
      enddo
      enddo
      enddo
    ENDIF  getpv11
      !cccccccccccccccccccccccccccccccccccccc
    ELSE
      !cccccccccccccccccccccccccccccccccccccc
      ! Cartesian grid, with terrain:
      !   (dum1 stores w at scalar-pts:)
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      do k=2,nk
      do j=1,nj+1
      do i=1,ni
        tem(i,j,k)=(-(va(i,j,k)-va(i,j,k-1))*rds(k)                                  &
                    +(wa(i,j,k)*rgz(i,j)-wa(i,j-1,k)*rgz(i,j-1))*rdy*vf(j)           &
                    +0.5*rds(k)*( (zt-sigma(k  ))*(dum1(i,j,k  )+dum1(i,j-1,k  ))    &
                                 -(zt-sigma(k-1))*(dum1(i,j,k-1)+dum1(i,j-1,k-1)) )  &
                               *(rgz(i,j)-rgz(i,j-1))*rdy*vf(j)                      &
                   )*0.5*( gz(i,j)+gz(i,j-1) )
      enddo
      enddo
      enddo
      IF( bbc.eq.1 )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do j=1,nj+1
        do i=1,ni
          tem(i,j,1)=tem(i,j,2)
        enddo
        enddo
      ELSEIF( bbc.eq.2 )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do j=1,nj+1
        do i=1,ni
          tem(i,j,1)=-2.0*va(i,j,1)*rds(2)*0.5*( gz(i,j-1)+gz(i,j) )
        enddo
        enddo
      ENDIF
      IF( tbc.eq.1 )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do j=1,nj+1
        do i=1,ni
          tem(i,j,nk+1)=tem(i,j,nk)
        enddo
        enddo
      ELSEIF( tbc.eq.2 )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do j=1,nj+1
        do i=1,ni
          tem(i,j,nk+1)=2.0*va(i,j,nk)*rdz*0.5*(mf(i,j-1,nk+1)+mf(i,j,nk+1))
        enddo
        enddo
      ENDIF
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      do k=1,nk
      do j=1,nj
      do i=1,ni
        xvort(i,j,k) = 0.25*(tem(i,j,k)+tem(i,j+1,k)+tem(i,j,k+1)+tem(i,j+1,k+1))
      enddo
      enddo
      enddo
    getpv1: IF( output_pv.eq.1 )THEN
      !cccccccccccccccccccccccccccccccccccccc
      ! here, zvort array stores d(th)/dx
      do k=1,nk
      do j=1,nj
      do i=1,ni+1
        zvort(i,j,k) = gzu(i,j)*(th(i,j,k)*rgz(i,j)-th(i-1,j,k)*rgz(i-1,j))*rdx*uf(i)  &
               +0.5*( gxu(i,j,k+1)*(dum2(i,j,k+1)+dum2(i-1,j,k+1))                     &
                     -gxu(i,j,k  )*(dum2(i,j,k  )+dum2(i-1,j,k  )) )*rdsf(k)
      enddo
      enddo
      enddo
      ! pv1:
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      do k=1,nk
      do j=1,nj
      do i=1,ni
        pv(i,j,k)=pv(i,j,k)+xvort(i,j,k)*0.5*( zvort(i,j,k)+zvort(i+1,j,k) )
      enddo
      enddo
      enddo
      !cccccccccccccccccccccccccccccccccccccc
    ENDIF  getpv1
    ENDIF
  else
      !cccccccccccccccccccccccccccccccccccccc
      ! Axisymmetric grid:
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      do k=2,nk
      do j=1,nj
      do i=1,ni
        tem(i,j,k) = -(va(i,j,k)-va(i,j,k-1))*rdz*mf(1,1,k)
      enddo
      enddo
      enddo
      IF( bbc.eq.1 )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do j=1,nj
        do i=1,ni
          tem(i,j,1)=tem(i,j,2)
        enddo
        enddo
      ELSEIF( bbc.eq.2 )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do j=1,nj
        do i=1,ni
          tem(i,j,1)=-2.0*va(i,j,1)*rdz*mf(1,1,1)
        enddo
        enddo
      ENDIF
      IF( tbc.eq.1 )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do j=1,nj
        do i=1,ni
          tem(i,j,nk+1)=tem(i,j,nk)
        enddo
        enddo
      ELSEIF( tbc.eq.2 )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do j=1,nj
        do i=1,ni
          tem(i,j,nk+1)=2.0*va(i,j,nk)*rdz*mf(1,1,nk+1)
        enddo
        enddo
      ENDIF
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      do k=1,nk
      do j=1,nj
      do i=1,ni
        xvort(i,j,k) = 0.5*(tem(i,j,k)+tem(i,j,k+1))
      enddo
      enddo
      enddo
      !cccccccccccccccccccccccccccccccccccccc
  endif

!-----------------------------------------------------------------------
! y-vort:

    tem=0.0
    IF(.not.terrain_flag)THEN
      !cccccccccccccccccccccccccccccccccccccc
      ! Cartesian grid, without terrain:
      ! and axisymmetric grid:

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      do k=2,nk
      do j=1,nj
      do i=1,ni+1
        tem(i,j,k) = (ua(i,j,k)-ua(i,j,k-1))*rdz*0.5*(mf(i-1,j,k)+mf(i,j,k))   &
                    -(wa(i,j,k)-wa(i-1,j,k))*rdx*uf(i)
      enddo
      enddo
      enddo
      IF( bbc.eq.1 )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do j=1,nj
        do i=1,ni+1
          tem(i,j,1)=tem(i,j,2)
        enddo
        enddo
      ELSEIF( bbc.eq.2 )THEN
      if( imove.eq.0 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do j=1,nj
        do i=1,ni+1
          tem(i,j,1)=2.0*ua(i,j,1)*rdz*0.5*(mf(i-1,j,1)+mf(i,j,1))
        enddo
        enddo
      else
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do j=1,nj
        do i=1,ni+1
          tem(i,j,1)=2.0*(ua(i,j,1)+umove)*rdz*0.5*(mf(i-1,j,1)+mf(i,j,1))
        enddo
        enddo
      endif
      ENDIF
      IF( tbc.eq.1 )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do j=1,nj
        do i=1,ni+1
          tem(i,j,nk+1)=tem(i,j,nk)
        enddo
        enddo
      ELSEIF( tbc.eq.2 )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do j=1,nj
        do i=1,ni+1
          tem(i,j,nk+1)=-2.0*ua(i,j,nk)*rdz*0.5*(mf(i-1,j,nk+1)+mf(i,j,nk+1))
        enddo
        enddo
      ENDIF
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      do k=1,nk
      do j=1,nj
      do i=1,ni
        yvort(i,j,k) = 0.25*(tem(i,j,k)+tem(i+1,j,k)+tem(i,j,k+1)+tem(i+1,j,k+1))
      enddo
      enddo
      enddo
      !cccccccccccccccccccccccccccccccccccccc
    getpv12:  IF( output_pv.eq.1 )THEN
      ! here, zvort array stores d(th)/dy
      do k=1,nk
      do j=1,nj+1
      do i=1,ni
        zvort(i,j,k) = (th(i,j,k)-th(i,j-1,k))*rdy*vf(j)
      enddo
      enddo
      enddo
      ! pv1:
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      do k=1,nk
      do j=1,nj
      do i=1,ni
        pv(i,j,k)=pv(i,j,k)+yvort(i,j,k)*0.5*( zvort(i,j,k)+zvort(i,j+1,k) )
      enddo
      enddo
      enddo
    ENDIF  getpv12
      !cccccccccccccccccccccccccccccccccccccc
    ELSE
      !cccccccccccccccccccccccccccccccccccccc
      ! Cartesian grid, with terrain:
      !   (dum1 stores w at scalar-pts:)
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      do k=2,nk
      do j=1,nj
      do i=1,ni+1
        tem(i,j,k)=( (ua(i,j,k)-ua(i,j,k-1))*rds(k)                                  &
                    -(wa(i,j,k)*rgz(i,j)-wa(i-1,j,k)*rgz(i-1,j))*rdx*uf(i)           &
                    -0.5*rds(k)*( (zt-sigma(k  ))*(dum1(i,j,k  )+dum1(i-1,j,k  ))    &
                                 -(zt-sigma(k-1))*(dum1(i,j,k-1)+dum1(i-1,j,k-1)) )  &
                               *(rgz(i,j)-rgz(i-1,j))*rdx*uf(i)                      &
                   )*0.5*( gz(i,j)+gz(i-1,j) )
      enddo
      enddo
      enddo
      IF( bbc.eq.1 )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do j=1,nj
        do i=1,ni+1
          tem(i,j,1)=tem(i,j,2)
        enddo
        enddo
      ELSEIF( bbc.eq.2 )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do j=1,nj
        do i=1,ni+1
          tem(i,j,1)=2.0*ua(i,j,1)*rds(2)*0.5*( gz(i-1,j)+gz(i,j) )
        enddo
        enddo
      ENDIF
      IF( tbc.eq.1 )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do j=1,nj
        do i=1,ni+1
          tem(i,j,nk+1)=tem(i,j,nk)
        enddo
        enddo
      ELSEIF( tbc.eq.2 )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do j=1,nj
        do i=1,ni+1
          tem(i,j,nk+1)=-2.0*ua(i,j,nk)*rds(nk)*0.5*( gz(i-1,j)+gz(i,j) )
        enddo
        enddo
      ENDIF
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      do k=1,nk
      do j=1,nj
      do i=1,ni
        yvort(i,j,k) = 0.25*(tem(i,j,k)+tem(i+1,j,k)+tem(i,j,k+1)+tem(i+1,j,k+1))
      enddo
      enddo
      enddo
    getpv2:  IF( output_pv.eq.1 )THEN
      !cccccccccccccccccccccccccccccccccccccc
      ! here, zvort array stores d(th)/dy
      do k=1,nk
      do j=1,nj+1
      do i=1,ni
        zvort(i,j,k) = gzv(i,j)*(th(i,j,k)*rgz(i,j)-th(i,j-1,k)*rgz(i,j-1))*rdy*vf(j)  &
               +0.5*( gyv(i,j,k+1)*(dum2(i,j,k+1)+dum2(i,j-1,k+1))                     &
                     -gyv(i,j,k  )*(dum2(i,j,k  )+dum2(i,j-1,k  )) )*rdsf(k)
      enddo
      enddo
      enddo
      ! pv1:
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      do k=1,nk
      do j=1,nj
      do i=1,ni
        pv(i,j,k)=pv(i,j,k)+yvort(i,j,k)*0.5*( zvort(i,j,k)+zvort(i,j+1,k) )
      enddo
      enddo
      enddo
    ENDIF  getpv2
      !cccccccccccccccccccccccccccccccccccccc
    ENDIF

!-----------------------------------------------------------------------
! z-vort:

    tem=0.0
    if(axisymm.eq.0)then
      IF(.not.terrain_flag)THEN
        !cccccccccccccccccccccccccccccccccccccc
        ! Cartesian grid, without terrain:
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk
          do j=1,nj+1
          do i=1,ni+1
            tem(i,j,k) = (va(i,j,k)-va(i-1,j,k))*rdx*uf(i)   &
                        -(ua(i,j,k)-ua(i,j-1,k))*rdy*vf(j)
          enddo
          enddo
          do j=1,nj
          do i=1,ni
            zvort(i,j,k) = 0.25*(tem(i,j,k)+tem(i+1,j,k)+tem(i,j+1,k)+tem(i+1,j+1,k))
          enddo
          enddo
        enddo
        !cccccccccccccccccccccccccccccccccccccc
      ELSE
        !cccccccccccccccccccccccccccccccccccccc
        ! Cartesian grid, with terrain:
        ! dum1 stores u at w-pts:
        ! dum2 stores v at w-pts:
!$omp parallel do default(shared)   &
!$omp private(i,j,k,r1,r2)
        do j=0,nj+2
          ! lowest model level:
          do i=0,ni+2
            dum1(i,j,1) = cgs1*ua(i,j,1)+cgs2*ua(i,j,2)+cgs3*ua(i,j,3)
            dum2(i,j,1) = cgs1*va(i,j,1)+cgs2*va(i,j,2)+cgs3*va(i,j,3)
          enddo
          ! upper-most model level:
          do i=0,ni+2
            dum1(i,j,nk+1) = cgt1*ua(i,j,nk)+cgt2*ua(i,j,nk-1)+cgt3*ua(i,j,nk-2)
            dum2(i,j,nk+1) = cgt1*va(i,j,nk)+cgt2*va(i,j,nk-1)+cgt3*va(i,j,nk-2)
          enddo
          ! interior:
          do k=2,nk
          r2 = (sigmaf(k)-sigma(k-1))*rds(k)
          r1 = 1.0-r2
          do i=0,ni+2
            dum1(i,j,k) = r1*ua(i,j,k-1)+r2*ua(i,j,k)
            dum2(i,j,k) = r1*va(i,j,k-1)+r2*va(i,j,k)
          enddo
          enddo
        enddo
!$omp parallel do default(shared)  &
!$omp private(i,j,k,r1)
        do k=1,nk
          do j=1,nj+1
          do i=1,ni+1
            r1 = zt/(zt-0.25*((zs(i-1,j-1)+zs(i,j))+(zs(i-1,j)+zs(i,j-1))))
            tem(i,j,k)=r1*( (va(i,j,k)*rgzv(i,j)-va(i-1,j,k)*rgzv(i-1,j))*rdx*uf(i)  &
                           +0.5*( (zt-sigmaf(k+1))*(dum2(i-1,j,k+1)+dum2(i,j,k+1))   &
                                 -(zt-sigmaf(k  ))*(dum2(i-1,j,k  )+dum2(i,j,k  ))   &
                                )*rdsf(k)*(rgzv(i,j)-rgzv(i-1,j))*rdx*uf(i) )        &
                      -r1*( (ua(i,j,k)*rgzu(i,j)-ua(i,j-1,k)*rgzu(i,j-1))*rdy*vf(j)  &
                           +0.5*( (zt-sigmaf(k+1))*(dum1(i,j-1,k+1)+dum1(i,j,k+1))   &
                                 -(zt-sigmaf(k  ))*(dum1(i,j-1,k  )+dum1(i,j,k  ))   &
                                )*rdsf(k)*(rgzu(i,j)-rgzu(i,j-1))*rdy*vf(j) )
          enddo
          enddo
          do j=1,nj
          do i=1,ni
            zvort(i,j,k) = 0.25*(tem(i,j,k)+tem(i+1,j,k)+tem(i,j+1,k)+tem(i+1,j+1,k))
          enddo
          enddo
        enddo
        !cccccccccccccccccccccccccccccccccccccc
      ENDIF
    else
      !cccccccccccccccccccccccccccccccccccccc
      ! Axisymmetric grid:
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      do k=1,nk
        do j=1,nj
        tem(1,j,k) = 0.0
        do i=2,ni+1
          tem(i,j,k) = (va(i,j,k)*xh(i)-va(i-1,j,k)*xh(i-1))*rdx*uf(i)/xf(i)
        enddo
        enddo
        do j=1,nj
        do i=1,ni
          zvort(i,j,k) = 0.5*(tem(i,j,k)+tem(i+1,j,k))
        enddo
        enddo
      enddo
      !cccccccccccccccccccccccccccccccccccccc
    endif


    getpv3:  IF( output_pv.eq.1 )THEN
      ! now, dum1 stores dt/dz:
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      do j=1,nj
        do k=2,nk
        do i=1,ni
          dum1(i,j,k) = (th(i,j,k)-th(i,j,k-1))*rdz*mf(i,j,k)
        enddo
        enddo
        do i=1,ni
          dum1(i,j,1) = (dgs3*th(i,j,3)+dgs2*th(i,j,2)+dgs1*th(i,j,1))*rdz*mh(i,j,1)
        enddo
        do i=1,ni
          dum1(i,j,nk+1) = (dgt3*th(i,j,nk-2)+dgt2*th(i,j,nk-1)+dgt1*th(i,j,nk))*rdz*mh(i,j,nk)
        enddo
        ! pv:
        do k=1,nk
        do i=1,ni
          pv(i,j,k)=pv(i,j,k)+zvort(i,j,k)*0.5*(dum1(i,j,k)+dum1(i,j,k+1))
          pv(i,j,k)=pv(i,j,k)*rr(i,j,k)
        enddo
        enddo
      enddo
    ENDIF  getpv3

!-----------------------------------------------------------------------

      IF( bbc.eq.3 )THEN
        ! cm1r18:  use log-layer equation below
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do j=1,nj
        do i=1,ni
          xvort(i,j,1) = -(ust(i,j)/(karman*(zh(i,j,1)+znt(i,j))))*(v1(i,j)/max(s1(i,j),0.01))
          yvort(i,j,1) =  (ust(i,j)/(karman*(zh(i,j,1)+znt(i,j))))*(u1(i,j)/max(s1(i,j),0.01))
        enddo
        enddo
      ENDIF

!-----------------------------------------------------------------------

      return
      end subroutine calcvort


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine calccpch(zh,zf,th0,qv0,cpc,cph,tha,qa)
      implicit none

      include 'input.incl'
      include 'constants.incl'

      real, intent(in),    dimension(ib:ie,jb:je,kb:ke) :: zh
      real, intent(in),    dimension(ib:ie,jb:je,kb:ke+1) :: zf
      real, intent(in),    dimension(ib:ie,jb:je,kb:ke) :: th0,qv0
      real, intent(inout), dimension(ib:ie,jb:je) :: cpc,cph
      real, intent(in),    dimension(ib:ie,jb:je,kb:ke) :: tha
      real, intent(in),    dimension(ibm:iem,jbm:jem,kbm:kem,numq) :: qa

      integer :: i,j,k,n
      real :: ql
      real, dimension(nk) :: bb

      ! defines top of cold pool / location to stop calculation of C
      real, parameter :: bcrit = -0.01

!$omp parallel do default(shared)  &
!$omp private(i,j,k,n,ql,bb)
    DO j=1,nj
    DO i=1,ni
      cpc(i,j) = 0.0
      cph(i,j) = 0.0
      bb = 0.0
      do k=1,nk
        bb(k) = g*tha(i,j,k)/th0(i,j,k)
      enddo
      if(imoist.eq.1)then
        do k=1,nk
          ql = 0.0
          do n=nql1,nql2
            ql=ql+qa(i,j,k,n)
          enddo
          if(iice.eq.1)then
            do n=nqs1,nqs2
              ql=ql+qa(i,j,k,n)
            enddo
          endif
          bb(k) = bb(k) + g*( repsm1*(qa(i,j,k,nqv)-qv0(i,j,k)) - ql )
        enddo
      endif
    ! only calculate cpc/cph if surface B is less than bcrit
    IF( bb(1).lt.bcrit .and. tha(i,j,1).le.-1.0 )THEN
      cpc(i,j) = - 2.0*bb(1)*(zf(i,j,2)-zf(i,j,1))
      k = 2
      do while( bb(k).lt.bcrit .and. k.lt.nk )
        if( cpc(i,j).lt.0.0 ) cpc(i,j) = 0.0
        cpc(i,j) = cpc(i,j) - 2.0*bb(k)*(zf(i,j,k+1)-zf(i,j,k))
        k = k + 1
      enddo
      if( cpc(i,j).gt.0.0 )then
        cpc(i,j) = sqrt(cpc(i,j))
        if(k.eq.nk)then
          cph(i,j) = zf(i,j,nk+1)
        else
          cph(i,j) = zh(i,j,k-1) + (zh(i,j,k)-zh(i,j,k-1))*(bcrit-bb(k-1))   &
                                                          /(bb(k)-bb(k-1))
        endif
        ! account for terrain:
        cph(i,j) = cph(i,j) - zf(i,j,1)
      endif
    ENDIF
    ENDDO
    ENDDO

      return
      end


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine calccref(cref,dbz)
      implicit none

      include 'input.incl'
      include 'constants.incl'
      include 'timestat.incl'

      real, intent(inout), dimension(ib:ie,jb:je) :: cref
      real, intent(in),    dimension(ib:ie,jb:je,kb:ke) :: dbz

      integer :: i,j,k

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      do j=1,nj
      do i=1,ni
        cref(i,j)=0.0
        do k=1,nk
          cref(i,j)=max(cref(i,j),dbz(i,j,k))
        enddo
      enddo
      enddo


      if(timestats.ge.1) time_write=time_write+mytime()

      return
      end


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine calcthe(zh,pi0,th0,the,rh,prs,ppi,tha,qa)
      implicit none

      include 'input.incl'
      include 'constants.incl'
      include 'timestat.incl'

      real, dimension(ib:ie,jb:je,kb:ke) :: zh,pi0,th0
      real, dimension(ib:ie,jb:je,kb:ke) :: the,rh,prs,ppi,tha
      real, dimension(ib:ie,jb:je,kb:ke,numq) :: qa

      integer i,j,k,n
      real tx,cpm
      real rslf
      real, parameter :: l0 = 2.555e6

! Reference:  Bryan, 2008, MWR, p. 5239

!$omp parallel do default(shared)  &
!$omp private(i,j,k,n,tx,cpm)
      do j=1,nj
      do k=1,nk
      do i=1,ni
        if(zh(i,j,k).le.10000.)then
          tx=(th0(i,j,k)+tha(i,j,k))*(pi0(i,j,k)+ppi(i,j,k))
          cpm=cp
          the(i,j,k)=tx                                              &
            *((p00*(1.0+qa(i,j,k,nqv)*reps)/prs(i,j,k))**(rd/cpm))   &
            *(rh(i,j,k)**(-qa(i,j,k,nqv)*rv/cpm))                    &
            *exp(l0*qa(i,j,k,nqv)/(cpm*tx))
        else
          the(i,j,k)=the(i,j,k-1)
        endif
      enddo
      enddo
      enddo

      if(timestats.ge.1) time_stat=time_stat+mytime()

      return
      end


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine cloud(nstat,rstat,zh,qci)
      implicit none
 
      include 'input.incl'
      include 'constants.incl'
      include 'timestat.incl'
 
      integer nstat
      real, dimension(stat_out) :: rstat
      real, dimension(ib:ie,jb:je,kb:ke) :: zh
      real, dimension(ib:ie,jb:je,kb:ke) :: qci

      integer i,j,k
      real qcbot(nk),qctop(nk),bot,top,var

!$omp parallel do default(shared)  &
!$omp private(k)
      do k=1,nk
        qcbot(k)=maxz
        qctop(k)=0.0
      enddo

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      do k=1,nk
        do j=1,nj
        do i=1,ni
          if(qci(i,j,k).ge.clwsat)then
            qctop(k)=max(qctop(k),zh(i,j,k))
            qcbot(k)=min(qcbot(k),zh(i,j,k))
          endif
        enddo
        enddo
      enddo

      top=0.0
      do k=1,nk
        top=max(top,qctop(k))
      enddo

      bot=maxz
      do k=1,nk
        bot=min(bot,qcbot(k))
      enddo


      if(bot.eq.maxz) bot=0.0

      write(6,100) 'QCTOP ',top,1,1,1,   &
                   'QCBOT ',bot,1,1,1
100   format(2x,a6,':',1x,f13.6,i5,i5,i5,   &
             4x,a6,':',1x,f13.6,i5,i5,i5)
 
      nstat = nstat + 1
      rstat(nstat) = top
      nstat = nstat + 1
      rstat(nstat) = bot


      if(timestats.ge.1) time_stat=time_stat+mytime()
 
      return
      end


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
 
 
      subroutine vertvort(nstat,rstat,xh,xf,uf,vf,zh,zs,rgzu,rgzv,rds,sigma,rdsf,sigmaf,dum1,dum2,ua,va)
      implicit none
 
      include 'input.incl'
      include 'constants.incl'
      include 'timestat.incl'

      integer nstat
      real, dimension(stat_out) :: rstat
      real, dimension(ib:ie) :: xh
      real, dimension(ib:ie+1) :: xf,uf
      real, dimension(jb:je+1) :: vf
      real, dimension(ib:ie,jb:je,kb:ke) :: zh
      real, intent(in), dimension(ib:ie,jb:je) :: zs
      real, intent(in), dimension(itb:ite,jtb:jte) :: rgzu,rgzv
      real, intent(in), dimension(kb:ke) :: rds,sigma
      real, intent(in), dimension(kb:ke+1) :: rdsf,sigmaf
      real, dimension(ib:ie,jb:je,kb:ke) :: dum1,dum2
      real, dimension(ib:ie+1,jb:je,kb:ke) :: ua
      real, dimension(ib:ie,jb:je+1,kb:ke) :: va

      integer i,j,k,n,n1km,n2km,n3km,n4km,n5km
      real vort,vmax,var
      real :: r1,r2
      character*6 text

!-----
!  note:  does not account for terrain

      n1km=nk+1
      n2km=nk+1
      n3km=nk+1
      n4km=nk+1
      n5km=nk+1

      do k=nk,1,-1
        if(zh(1,1,k).ge.1000.0) n1km=k
        if(zh(1,1,k).ge.2000.0) n2km=k
        if(zh(1,1,k).ge.3000.0) n3km=k
        if(zh(1,1,k).ge.4000.0) n4km=k
        if(zh(1,1,k).ge.5000.0) n5km=k
      enddo

      IF(terrain_flag)THEN
        ! dum1 stores u at w-pts:
        ! dum2 stores v at w-pts:
!$omp parallel do default(shared)   &
!$omp private(i,j,k,r1,r2)
        do j=0,nj+2
          ! lowest model level:
          do i=0,ni+2
            dum1(i,j,1) = cgs1*ua(i,j,1)+cgs2*ua(i,j,2)+cgs3*ua(i,j,3)
            dum2(i,j,1) = cgs1*va(i,j,1)+cgs2*va(i,j,2)+cgs3*va(i,j,3)
          enddo

          ! upper-most model level:
          do i=0,ni+2
            dum1(i,j,nk+1) = cgt1*ua(i,j,nk)+cgt2*ua(i,j,nk-1)+cgt3*ua(i,j,nk-2)
            dum2(i,j,nk+1) = cgt1*va(i,j,nk)+cgt2*va(i,j,nk-1)+cgt3*va(i,j,nk-2)
          enddo

          ! interior:
          do k=2,nk
          r2 = (sigmaf(k)-sigma(k-1))*rds(k)
          r1 = 1.0-r2
          do i=0,ni+2
            dum1(i,j,k) = r1*ua(i,j,k-1)+r2*ua(i,j,k)
            dum2(i,j,k) = r1*va(i,j,k-1)+r2*va(i,j,k)
          enddo
          enddo
        enddo
      ENDIF

      do n=1,6
        vmax = 0.0
        if(n.eq.1)then
          k=1
          text='VORSFC'
        elseif(n.eq.2)then
          k=n1km
          text='VOR1KM'
        elseif(n.eq.3)then
          k=n2km
          text='VOR2KM'
        elseif(n.eq.4)then
          k=n3km
          text='VOR3KM'
        elseif(n.eq.5)then
          k=n4km
          text='VOR4KM'
        elseif(n.eq.6)then
          k=n5km
          text='VOR5KM'
        endif
    kcheck:  IF( k.le.nk )THEN
        vmax=-9999999.
    IF( axisymm.eq.0 )THEN
      IF(.not.terrain_flag)THEN
        ! Cartesian grid, without terrain:
        do j=1+ibs,nj+1-ibn
        do i=1+ibw,ni+1-ibe
          vort=(va(i,j,k)-va(i-1,j,k))*rdx*uf(i)   &
              -(ua(i,j,k)-ua(i,j-1,k))*rdy*vf(j)
          vmax=max(vmax,vort)
        enddo
        enddo
      ELSE
        ! Cartesian grid, with terrain:
        do j=1+ibs,nj+1-ibn
        do i=1+ibw,ni+1-ibe
          r1 = zt/(zt-0.25*((zs(i-1,j-1)+zs(i,j))+(zs(i-1,j)+zs(i,j-1))))
          vort=( r1*(va(i,j,k)*rgzv(i,j)-va(i-1,j,k)*rgzv(i-1,j))*rdx*uf(i)  &
                +0.5*( (zt-sigmaf(k+1))*(dum2(i-1,j,k+1)+dum2(i,j,k+1))      &
                      -(zt-sigmaf(k  ))*(dum2(i-1,j,k  )+dum2(i,j,k  ))      &
                     )*rdsf(k)*r1*(rgzv(i,j)-rgzv(i-1,j))*rdx*uf(i) )        &
              -( r1*(ua(i,j,k)*rgzu(i,j)-ua(i,j-1,k)*rgzu(i,j-1))*rdy*vf(j)  &
                +0.5*( (zt-sigmaf(k+1))*(dum1(i,j-1,k+1)+dum1(i,j,k+1))      &
                      -(zt-sigmaf(k  ))*(dum1(i,j-1,k  )+dum1(i,j,k  ))      &
                     )*rdsf(k)*r1*(rgzu(i,j)-rgzu(i,j-1))*rdy*vf(j) )
          vmax=max(vmax,vort)
        enddo
        enddo
      ENDIF
    ELSE
        ! axisymmetric grid
        do j=1,nj+1
        do i=2,ni+1
          vort=(xh(i)*va(i,j,k)-xh(i-1)*va(i-1,j,k))*rdx*uf(i)/xf(i)
          vmax=max(vmax,vort)
        enddo
        enddo
    ENDIF
    ENDIF  kcheck
        write(6,100) text,vmax
        nstat = nstat + 1
        rstat(nstat) = vmax
      ENDDO

100   format(2x,a6,':',1x,e13.6)

      if(timestats.ge.1) time_stat=time_stat+mytime()
 
      return
      end


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

 
      subroutine calccfl(nstat,rstat,dt,acfl,uh,vh,mh,ua,va,wa,writeit)
      implicit none

      include 'input.incl'
      include 'constants.incl'
      include 'timestat.incl'
 
      integer nstat
      real, dimension(stat_out) :: rstat
      real :: dt
      double precision :: acfl
      real, intent(in), dimension(ib:ie) :: uh
      real, intent(in), dimension(jb:je) :: vh
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: mh
      real, dimension(ib:ie+1,jb:je,kb:ke) :: ua
      real, dimension(ib:ie,jb:je+1,kb:ke) :: va
      real, dimension(ib:ie,jb:je,kb:ke+1) :: wa
      integer :: writeit
 
      integer i,j,k
      integer imax,jmax,kmax
      integer imaxt(nk),jmaxt(nk),kmaxt(nk)
      real dtdx,dtdy,dtdz,cfl(nk),fmax
      real :: wsp
      integer :: loc
      real, dimension(2) :: mmax,nmax
 
      dtdx=0.5*dt*rdx
      dtdy=0.5*dt*rdy
      dtdz=0.5*dt*rdz

      cfl = -1.0
      imaxt = 0
      jmaxt = 0
      kmaxt = 0

!$omp parallel do default(shared)  &
!$omp private(i,j,k,wsp)
      do k=1,nk
      if(nx.gt.1.and.ny.gt.1)then
        do j=1,nj
        do i=1,ni
          wsp = sqrt( ( ((ua(i,j,k)+ua(i+1,j,k))*dtdx*uh(i))**2     &
                       +((va(i,j,k)+va(i,j+1,k))*dtdy*vh(j))**2 )   &
                       +((wa(i,j,k)+wa(i,j,k+1))*dtdz*mh(i,j,k))**2 )
          if( wsp.gt.cfl(k) )then
            cfl(k) = wsp
            imaxt(k)=i
            jmaxt(k)=j
            kmaxt(k)=k
          endif
        enddo
        enddo
      elseif(nx.gt.1)then
        do j=1,nj
        do i=1,ni
          wsp = sqrt( ((ua(i,j,k)+ua(i+1,j,k))*dtdx*uh(i))**2     &
                     +((wa(i,j,k)+wa(i,j,k+1))*dtdz*mh(i,j,k))**2 )
          if( wsp.gt.cfl(k) )then
            cfl(k) = wsp
            imaxt(k)=i
            jmaxt(k)=j
            kmaxt(k)=k
          endif
        enddo
        enddo
      elseif(axisymm.eq.0.and.ny.gt.1)then
        do j=1,nj
        do i=1,ni
          wsp = sqrt( ((va(i,j,k)+va(i,j+1,k))*dtdy*vh(j))**2     &
                     +((wa(i,j,k)+wa(i,j,k+1))*dtdz*mh(i,j,k))**2 )
          if( wsp.gt.cfl(k) )then
            cfl(k) = wsp
            imaxt(k)=i
            jmaxt(k)=j
            kmaxt(k)=k
          endif
        enddo
        enddo
      endif
      enddo

      fmax=-99999999.
      imax=1
      jmax=1
      kmax=1
      do k=1,nk
        if(cfl(k).gt.fmax)then
          fmax=cfl(k)
          imax=imaxt(k)
          jmax=jmaxt(k)
          kmax=kmaxt(k)
        endif
      enddo


    IF(writeit.eq.1)THEN
      nstat = nstat + 1
      IF( adapt_dt.eq.1 )THEN
        write(6,100) 'CFLMAX',sngl(acfl),imax,jmax,kmax
        rstat(nstat) = sngl(acfl)
      ELSE
        write(6,100) 'CFLMAX',fmax,imax,jmax,kmax
        rstat(nstat) = fmax
      ENDIF
100   format(2x,a6,':',1x,f13.6,i5,i5,i5)
    ENDIF


!!!      cflmax = fmax

      if(fmax.ge.1.50) stopit=.true.
 
      if(timestats.ge.1) time_stat=time_stat+mytime()
 
      return
      end


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine calccflquick(dt,uh,vh,mh,ua,va,wa)
      implicit none

      include 'input.incl'
      include 'constants.incl'
      include 'timestat.incl'
 
      real, intent(in) :: dt
      real, intent(in), dimension(ib:ie) :: uh
      real, intent(in), dimension(jb:je) :: vh
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: mh
      real, intent(in), dimension(ib:ie+1,jb:je,kb:ke) :: ua
      real, intent(in), dimension(ib:ie,jb:je+1,kb:ke) :: va
      real, intent(in), dimension(ib:ie,jb:je,kb:ke+1) :: wa
 
      integer :: i,j,k
      real :: dtdx,dtdy,dtdz,fmax,gmax,wsp,tem
      real, dimension(nk) :: cfl
 
      dtdx=0.5*dt*rdx
      dtdy=0.5*dt*rdy
      dtdz=0.5*dt*rdz

      cfl = 0.0

!$omp parallel do default(shared)  &
!$omp private(i,j,k,wsp,tem)
      do k=1,nk
      if(nx.gt.1.and.ny.gt.1)then
        do j=1,nj
        do i=1,ni
          wsp = sqrt( ( ((ua(i,j,k)+ua(i+1,j,k))*dtdx*uh(i))**2     &
                       +((va(i,j,k)+va(i,j+1,k))*dtdy*vh(j))**2 )   &
                       +((wa(i,j,k)+wa(i,j,k+1))*dtdz*mh(i,j,k))**2 )
          cfl(k) = max( cfl(k) , wsp )
          if( wsp.ge.1.30 ) print *,'  cfl,myid,i,j,k = ',wsp,myid,i,j,k
        enddo
        enddo
      elseif(nx.gt.1)then
        do j=1,nj
        do i=1,ni
          wsp = sqrt( ((ua(i,j,k)+ua(i+1,j,k))*dtdx*uh(i))**2     &
                     +((wa(i,j,k)+wa(i,j,k+1))*dtdz*mh(i,j,k))**2 )
          cfl(k) = max( cfl(k) , wsp )
          if( wsp.ge.1.30 ) print *,'  cfl,myid,i,j,k = ',wsp,myid,i,j,k
        enddo
        enddo
      elseif(axisymm.eq.0.and.ny.gt.1)then
        do j=1,nj
        do i=1,ni
          wsp = sqrt( ((va(i,j,k)+va(i,j+1,k))*dtdy*vh(j))**2     &
                     +((wa(i,j,k)+wa(i,j,k+1))*dtdz*mh(i,j,k))**2 )
          cfl(k) = max( cfl(k) , wsp )
          if( wsp.ge.1.30 ) print *,'  cfl,myid,i,j,k = ',wsp,myid,i,j,k
        enddo
        enddo
      endif
      enddo

      fmax=-99999999.
      do k=1,nk
        fmax = max( fmax , cfl(k) )
      enddo


      if(fmax.ge.1.50) stopit=.true.

      cflmax = fmax

      if(timestats.ge.1) time_cflq=time_cflq+mytime()
 
      end subroutine calccflquick


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine calcksmax(nstat,rstat,dt,uh,vh,mf,kmh,kmv,khh,khv)
      implicit none

      include 'input.incl'
      include 'constants.incl'
      include 'timestat.incl'

      integer nstat
      real, dimension(stat_out) :: rstat
      real :: dt
      real, dimension(ib:ie) :: uh
      real, dimension(jb:je) :: vh
      real, dimension(ib:ie,jb:je,kb:ke+1) :: mf
      real, dimension(ibc:iec,jbc:jec,kbc:kec) :: kmh,kmv,khh,khv

      integer i,j,k
      integer imaxh,jmaxh,kmaxh
      integer imaxv,jmaxv,kmaxv
      integer imaxth(nk),jmaxth(nk),kmaxth(nk)
      integer imaxtv(nk),jmaxtv(nk),kmaxtv(nk)
      real dtdx,dtdy,dtdz,tem,ksh(nk),ksv(nk),fhmax,fvmax
      integer :: loc
      real, dimension(2) :: mmax,nmax

    IF(iturb.ge.1)THEN

      dtdx=dt*rdx*rdx
      dtdy=dt*rdy*rdy
      dtdz=dt*rdz*rdz

!$omp parallel do default(shared)  &
!$omp private(i,j,k,tem)
      do k=2,nk
        ksh(k)=-99999.0
        ksv(k)=-99999.0
        do j=1,nj
        do i=1,ni
!!!          tem = max( abs(kmh(i,j,k))*dtdx*uh(i)*uh(i) ,   &
!!!                     abs(khh(i,j,k))*dtdx*uh(i)*uh(i) )
          tem = khh(i,j,k)*dtdx*uh(i)*uh(i)
          if( tem.gt.ksh(k) )then
            ksh(k)=tem
            imaxth(k)=i
            jmaxth(k)=j
            kmaxth(k)=k
          endif
!!!          tem = max( abs(kmh(i,j,k))*dtdy*vh(j)*vh(j) ,   &
!!!                     abs(khh(i,j,k))*dtdy*vh(j)*vh(j) )
          tem = khh(i,j,k)*dtdy*vh(j)*vh(j)
          if( tem.gt.ksh(k) )then
            ksh(k)=tem
            imaxth(k)=i
            jmaxth(k)=j
            kmaxth(k)=k
          endif
!!!          tem = max( abs(kmv(i,j,k))*dtdz*mf(i,j,k)*mf(i,j,k) ,   &
!!!                     abs(khv(i,j,k))*dtdz*mf(i,j,k)*mf(i,j,k) )
          tem = khv(i,j,k)*dtdz*mf(i,j,k)*mf(i,j,k)
          if( tem.gt.ksv(k) )then
            ksv(k)=tem
            imaxtv(k)=i
            jmaxtv(k)=j
            kmaxtv(k)=k
          endif
        enddo
        enddo
      enddo

      fhmax=-99999999.
      fvmax=-99999999.
      imaxh=1
      jmaxh=1
      kmaxh=1
      imaxv=1
      jmaxv=1
      kmaxv=1
      do k=2,nk
        if(ksh(k).gt.fhmax)then
          fhmax=ksh(k)
          imaxh=imaxth(k)
          jmaxh=jmaxth(k)
          kmaxh=kmaxth(k)
        endif
        if(ksv(k).gt.fvmax)then
          fvmax=ksv(k)
          imaxv=imaxtv(k)
          jmaxv=jmaxtv(k)
          kmaxv=kmaxtv(k)
        endif
      enddo

    ELSE

      fhmax = 0.0
      fvmax = 0.0
      imaxh = 0
      jmaxh = 0
      kmaxh = 0
      imaxv = 0
      jmaxv = 0
      kmaxv = 0

    ENDIF


      write(6,100) 'KSHMAX',fhmax,imaxh,jmaxh,kmaxh

      nstat = nstat + 1
      rstat(nstat) = fhmax

      write(6,100) 'KSVMAX',fvmax,imaxv,jmaxv,kmaxv

      nstat = nstat + 1
      rstat(nstat) = fvmax

100   format(2x,a6,':',1x,g13.6,i5,i5,i5)


      if(timestats.ge.1) time_stat=time_stat+mytime()

      return
      end


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine getrmw(nstat,rstat,xh,zh,ua,va)
      implicit none

      include 'input.incl'
      include 'timestat.incl'

      integer, intent(inout) :: nstat
      real, intent(inout), dimension(stat_out) :: rstat
      real, intent(in), dimension(ib:ie) :: xh
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: zh
      real, intent(in), dimension(ib:ie+1,jb:je,kb:ke) :: ua
      real, intent(in), dimension(ib:ie,jb:je+1,kb:ke) :: va

      integer :: i,k,imax,jmax,kmax
      real :: wspd
      real :: rmax,zmax,vmax

      integer, dimension(nk) :: imaxt,kmaxt
      real, dimension(nk) :: rmaxt,zmaxt,vmaxt

      ! Note:  only called from axisymmetric simulation

!$omp parallel do default(shared)  &
!$omp private(i,k,wspd)
      do k=1,nk
        vmaxt(k) = 0.0
        do i=1,ni
          wspd = sqrt( (0.5*(ua(i,1,k)+ua(i+1,1,k)))**2 + va(i,1,k)**2 )
          IF( wspd.ge.vmaxt(k) )THEN
            vmaxt(k) = wspd
            rmaxt(k) = xh(i)
            zmaxt(k) = zh(i,1,k)
            imaxt(k) = i
            kmaxt(k) = k
          ENDIF
        enddo
      enddo

      vmax = 0.0
      do k=1,nk
        IF( vmaxt(k).ge.vmax )THEN
          vmax = vmaxt(k)
          rmax = rmaxt(k)
          zmax = zmaxt(k)
          imax = imaxt(k)
          kmax = kmaxt(k)
        ENDIF
      enddo

      jmax = 1

      write(6,131) 'RMW   ',rmax,imax,jmax,kmax
      write(6,131) 'ZMW   ',zmax,imax,jmax,kmax
131   format(2x,a6,':',1x,f13.6,i5,i5,i5)

      nstat = nstat + 1
      rstat(nstat) = rmax
      nstat = nstat + 1
      rstat(nstat) = zmax

      if(timestats.ge.1) time_stat=time_stat+mytime()

      return
      end


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine calcmass(nstat,rstat,ruh,rvh,rmh,rho)
      implicit none

      include 'input.incl'
      include 'constants.incl'
      include 'timestat.incl'
 
      integer nstat
      real, dimension(stat_out) :: rstat
      real, dimension(ib:ie) :: ruh
      real, dimension(jb:je) :: rvh
      real, dimension(ib:ie,jb:je,kb:ke) :: rmh
      real, dimension(ib:ie,jb:je,kb:ke) :: rho
 
      integer i,j,k
      double precision :: tmass,var
      double precision, dimension(nk) :: foo
 
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      do k=1,nk
        foo(k)=0.0d0
        do j=1,nj
        do i=1,ni
          foo(k)=foo(k)+rho(i,j,k)*ruh(i)*rvh(j)*rmh(i,j,k)
        enddo
        enddo
      enddo
 
      tmass=0.0d0
      do k=1,nk
        tmass=tmass+foo(k)
      enddo


      tmass=tmass*(dx*dy*dz)
 
      write(6,100) 'TMASS ',tmass
100   format(2x,a6,':',1x,e13.6)
 
      nstat = nstat + 1
      rstat(nstat) = tmass

 
      if(timestats.ge.1) time_stat=time_stat+mytime()
 
      return
      end


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
 
 
      subroutine totmois(nstat,rstat,train,ruh,rvh,rmh,qv,ql,qi,rho)
      implicit none

      include 'input.incl'
      include 'constants.incl'
      include 'timestat.incl'

      integer nstat
      real, dimension(stat_out) :: rstat
      double precision :: train
      real, dimension(ib:ie) :: ruh
      real, dimension(jb:je) :: rvh
      real, dimension(ib:ie,jb:je,kb:ke) :: rmh
      real, dimension(ib:ie,jb:je,kb:ke) :: qv,ql,qi,rho
 
      integer i,j,k
      double precision :: tmass,var
      double precision, dimension(nk) :: foo

!$omp parallel do default(shared)  &
!$omp private(k)
      do k=1,nk
        foo(k)=0.0d0
      enddo
 
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      do k=1,nk
        do j=1,nj
        do i=1,ni
          foo(k)=foo(k)+rho(i,j,k)*(qv(i,j,k)+ql(i,j,k)+qi(i,j,k))*ruh(i)*rvh(j)*rmh(i,j,k)
        enddo
        enddo
      enddo
 
      tmass=0.0d0
      do k=1,nk
        tmass=tmass+foo(k)
      enddo


!!!      tmass=tmass*(dx*dy*dz)+train
      ! cm1r18:  do not include rain:
      tmass=tmass*(dx*dy*dz)

      write(6,100) 'TMOIS ',tmass
100   format(2x,a6,':',1x,e13.6)
 
      nstat = nstat + 1
      rstat(nstat) = tmass

 
      if(timestats.ge.1) time_stat=time_stat+mytime()
 
      return
      end


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine totq(nstat,rstat,ruh,rvh,rmh,q,rho,aname)
      implicit none

      include 'input.incl'
      include 'constants.incl'
      include 'timestat.incl'

      integer nstat
      real, dimension(stat_out) :: rstat
      real, dimension(ib:ie) :: ruh
      real, dimension(jb:je) :: rvh
      real, dimension(ib:ie,jb:je,kb:ke) :: rmh
      real, dimension(ib:ie,jb:je,kb:ke) :: q,rho
      character*6 aname

      integer i,j,k
      double precision :: tmass,var
      double precision, dimension(nk) :: foo

!$omp parallel do default(shared)  &
!$omp private(k)
      do k=1,nk
        foo(k)=0.0d0
      enddo

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      do k=1,nk
      do j=1,nj
      do i=1,ni
        foo(k)=foo(k)+rho(i,j,k)*q(i,j,k)*ruh(i)*rvh(j)*rmh(i,j,k)
      enddo
      enddo
      enddo

      tmass=0.0d0
      do k=1,nk
        tmass=tmass+foo(k)
      enddo


      tmass=tmass*(dx*dy*dz)

      write(6,100) aname,tmass
100   format(2x,a6,':',1x,e13.6)

      nstat = nstat + 1
      rstat(nstat) = tmass


      if(timestats.ge.1) time_stat=time_stat+mytime()

      return
      end


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
 
 
      subroutine calcener(nstat,rstat,ruh,rvh,zh,rmh,pi0,th0,rho,ua,va,wa,ppi,tha,   &
                          qv,ql,qi,vr)
      implicit none

      include 'input.incl'
      include 'constants.incl'
      include 'timestat.incl'
 
      integer nstat
      real, dimension(stat_out) :: rstat
      real, dimension(ib:ie) :: ruh
      real, dimension(jb:je) :: rvh
      real, dimension(ib:ie,jb:je,kb:ke) :: zh,rmh,pi0,th0
      real, dimension(ib:ie,jb:je,kb:ke) :: rho
      real, dimension(ib:ie+1,jb:je,kb:ke) :: ua
      real, dimension(ib:ie,jb:je+1,kb:ke) :: va
      real, dimension(ib:ie,jb:je,kb:ke+1) :: wa
      real, dimension(ib:ie,jb:je,kb:ke) :: ppi,tha,qv,ql,qi,vr
 
      integer i,j,k
      double precision :: u,v,w,tmp,qtot,ek,ei,ep,et,le,var,tem
      double precision, dimension(nk) :: foo1,foo2,foo3,foo4

!$omp parallel do default(shared)  &
!$omp private(i,j,k,u,v,w,tmp,qtot,tem)
      do k=1,nk
        foo1(k)=0.0d0      ! = ek
        foo2(k)=0.0d0      ! = ei
        foo3(k)=0.0d0      ! = ep
        foo4(k)=0.0d0      ! = le
        do j=1,nj
        do i=1,ni
          tem=ruh(i)*rvh(j)*rmh(i,j,k)
          u=umove+0.5*(ua(i,j,k)+ua(i+1,j,k))
          v=vmove+0.5*(va(i,j,k)+va(i,j+1,k))
          w=0.5*(wa(i,j,k)+wa(i,j,k+1))
          qtot=qv(i,j,k)+ql(i,j,k)+qi(i,j,k)
          foo1(k)=foo1(k)+rho(i,j,k)*tem*(1.0+qtot)*0.5*(        &
                         0.5*( ua(i,j,k)**2 + ua(i+1,j,k)**2 )   &
                        +0.5*( va(i,j,k)**2 + va(i,j+1,k)**2 )   &
                        +0.5*( wa(i,j,k)**2 + wa(i,j,k+1)**2 ) ) &
               +ql(i,j,k)*rho(i,j,k)*tem*0.5*(vr(i,j,k)**2-2.0*w*vr(i,j,k))
          tmp=(th0(i,j,k)+tha(i,j,k))*(pi0(i,j,k)+ppi(i,j,k))
          foo2(k)=foo2(k)+rho(i,j,k)*tem*(cv+cvv*qv(i,j,k))*tmp
          foo3(k)=foo3(k)+rho(i,j,k)*tem*(1.0+qtot)*g*zh(i,j,k)
          foo4(k)=foo4(k)+rho(i,j,k)*tem*ql(i,j,k)*(cpl*tmp-lv1)   &
                         +rho(i,j,k)*tem*qi(i,j,k)*(cpi*tmp-ls1)
        enddo
        enddo
      enddo

      ek=0.0d0
      ei=0.0d0
      ep=0.0d0
      le=0.0d0
 
      do k=1,nk
        ek=ek+foo1(k)
        ei=ei+foo2(k)
        ep=ep+foo3(k)
        le=le+foo4(k)
      enddo

      ek=ek*(dx*dy*dz)
      ei=ei*(dx*dy*dz)
      ep=ep*(dx*dy*dz)
      le=le*(dx*dy*dz)


      et=ek+ei+ep+le
 
      write(6,100) 'TENERG',et
100   format(2x,a6,':',1x,e13.6)

      nstat = nstat + 1
      rstat(nstat) = ek
      nstat = nstat + 1
      rstat(nstat) = ei
      nstat = nstat + 1
      rstat(nstat) = ep
      nstat = nstat + 1
      rstat(nstat) = le
      nstat = nstat + 1
      rstat(nstat) = et

 
      if(timestats.ge.1) time_stat=time_stat+mytime()
 
      return
      end


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
 
 
      subroutine calcmoe(nstat,rstat,ruh,rvh,rmh,rho,ua,va,wa,qv,ql,qi,vr)
      implicit none
 
      include 'input.incl'
      include 'constants.incl'
      include 'timestat.incl'
 
      integer nstat
      real, dimension(stat_out) :: rstat
      real, dimension(ib:ie) :: ruh
      real, dimension(jb:je) :: rvh
      real, dimension(ib:ie,jb:je,kb:ke) :: rmh
      real, dimension(ib:ie,jb:je,kb:ke) :: rho
      real, dimension(ib:ie+1,jb:je,kb:ke) :: ua
      real, dimension(ib:ie,jb:je+1,kb:ke) :: va
      real, dimension(ib:ie,jb:je,kb:ke+1) :: wa
      real, dimension(ib:ie,jb:je,kb:ke) :: qv,ql,qi,vr
 
      integer i,j,k
      double precision :: tmu,tmv,tmw,qtot,var,tem
      double precision, dimension(nk) :: foo1,foo2,foo3

!$omp parallel do default(shared)  &
!$omp private(k)
      do k=1,nk
        foo1(k)=0.0d0
        foo2(k)=0.0d0
        foo3(k)=0.0d0
      enddo
 
!$omp parallel do default(shared)  &
!$omp private(i,j,k,qtot,tem)
      do k=1,nk
        do j=1,nj
        do i=1,ni
          qtot=qv(i,j,k)+ql(i,j,k)+qi(i,j,k)
          tem=ruh(i)*rvh(j)*rmh(i,j,k)
          foo1(k)=foo1(k)   &
                +rho(i,j,k)*tem*(1.0+qtot)*( umove+0.5*(ua(i,j,k)+ua(i+1,j,k)) )
          foo2(k)=foo2(k)   &
                +rho(i,j,k)*tem*(1.0+qtot)*( vmove+0.5*(va(i,j,k)+va(i,j+1,k)) )
          foo3(k)=foo3(k)                                                &
                +rho(i,j,k)*tem*(1.0+qtot)*( 0.5*(wa(i,j,k)+wa(i,j,k+1)) )   &
                -rho(i,j,k)*tem*ql(i,j,k)*vr(i,j,k)
        enddo
        enddo
      enddo

      tmu=0.0d0
      tmv=0.0d0
      tmw=0.0d0
      do k=1,nk
        tmu=tmu+foo1(k)
        tmv=tmv+foo2(k)
        tmw=tmw+foo3(k)
      enddo

      tmu=tmu*(dx*dy*dz)
      tmv=tmv*(dx*dy*dz)
      tmw=tmw*(dx*dy*dz)

 
      write(6,100) 'TMU   ',tmu
      write(6,100) 'TMV   ',tmv
      write(6,100) 'TMW   ',tmw
100   format(2x,a6,':',1x,e13.6)
 
      nstat = nstat + 1
      rstat(nstat) = tmu
      nstat = nstat + 1
      rstat(nstat) = tmv
      nstat = nstat + 1
      rstat(nstat) = tmw

 
      if(timestats.ge.1) time_stat=time_stat+mytime()
 
      return
      end


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine tmf(nstat,rstat,ruh,rvh,rho,wa)
      implicit none

      include 'input.incl'
      include 'constants.incl'
      include 'timestat.incl'

      integer nstat
      real, dimension(stat_out) :: rstat
      real, dimension(ib:ie) :: ruh
      real, dimension(jb:je) :: rvh
      real, dimension(ib:ie,jb:je,kb:ke) :: rho
      real, dimension(ib:ie,jb:je,kb:ke+1) :: wa

      integer i,j,k
      double precision :: tmfu,tmfd,mf,var
      double precision, dimension(nk) :: foo1,foo2

!$omp parallel do default(shared)  &
!$omp private(i,j,k,mf)
      do k=1,nk
        foo1(k)=0.0d0
        foo2(k)=0.0d0
        do j=1,nj
        do i=1,ni
          mf=rho(i,j,k)*0.5*(wa(i,j,k)+wa(i,j,k+1))*ruh(i)*rvh(j)
          foo1(k)=foo1(k)+max(mf,0.0d0)
          foo2(k)=foo2(k)+min(mf,0.0d0)
        enddo
        enddo
      enddo

      tmfu=0.0d0
      tmfd=0.0d0
      do k=1,nk
        tmfu=tmfu+foo1(k)
        tmfd=tmfd+foo2(k)
      enddo


      tmfu=tmfu*dx*dy
      tmfd=tmfd*dx*dy

      write(6,100) 'TMFU  ',tmfu
      write(6,100) 'TMFD  ',tmfd
100   format(2x,a6,':',1x,e13.6)

      nstat = nstat + 1
      rstat(nstat) = tmfu
      nstat = nstat + 1
      rstat(nstat) = tmfd


      if(timestats.ge.1) time_stat=time_stat+mytime()

      return
      end


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine zinterp(sigma,zs,zh,dum1,dum2)
      implicit none

      include 'input.incl'
      include 'constants.incl'
      include 'timestat.incl'

      real, dimension(kb:ke) :: sigma
      real, dimension(ib:ie,jb:je) :: zs
      real, dimension(ib:ie,jb:je,kb:ke) :: zh,dum1,dum2

      integer i,j,k,kk,kup,kdn
      real, dimension(nk) :: zref

      do k=1,nk
!!!        zref(k)=(k*dz-0.5*dz)
        zref(k)=sigma(k)
      enddo

      do k=1,nk
      do j=1,nj
      do i=1,ni
        dum2(i,j,k)=dum1(i,j,k)
      enddo
      enddo
      enddo

      do k=1,nk
      do j=1,nj
      do i=1,ni
        if( (zref(k).lt.zh(i,j,1)).or.(zref(k).gt.zh(i,j,nk)) )then
          if( zref(k).gt.0.5*zh(i,j,1) .and. zref(k).gt.zs(i,j) )then
            ! 2nd-order extrapolation:
            dum1(i,j,k)=dum2(i,j,1)-(zh(i,j,1)-zref(k))                             &
                                   *(-3.0*dum2(i,j,1)+4.0*dum2(i,j,2)-dum2(i,j,3))  &
                                   *0.25/(zh(i,j,1)-zs(i,j))
          else
            dum1(i,j,k)=-99999999.
          endif
        elseif(zs(i,j).lt.0.1 .or. zref(k).eq.zh(i,j,1))then
          dum1(i,j,k)=dum2(i,j,k)
        else
          kup=0
          kdn=0
          do kk=1,nk
            if(zref(k).gt.zh(i,j,kk)) kdn=kk
          enddo
          kup=kdn+1
          if(kup.le.0.or.kdn.le.0.or.kup.ge.nk+1.or.kdn.ge.nk+1)then
            print *,kdn,kup
            print *,zs(i,j),zh(i,j,kdn),zref(k),zh(i,j,kup)
            print *,i,j,k
            call stopcm1
          endif
          dum1(i,j,k)=dum2(i,j,kdn)+(dum2(i,j,kup)-dum2(i,j,kdn))   &
                                   *(  zref(k  )  -zh(i,j,kdn))     &
                                   /(  zh(i,j,kup)-zh(i,j,kdn))
        endif
      enddo
      enddo
      enddo

      return
      end


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

!
! ---------------------------------------------------------------------
! THIS FUNCTION CALCULATES THE LIQUID SATURATION VAPOR MIXING RATIO AS
! A FUNCTION OF TEMPERATURE AND PRESSURE
!
      FUNCTION RSLF(P,T)

      IMPLICIT NONE
      include 'input.incl'
      include 'constants.incl'
      REAL ESL,RSLF,X,T,P,C0,C1,C2,C3,C4,C5,C6,C7,C8
      PARAMETER (C0= .611583699E03)
      PARAMETER (C1= .444606896E02)
      PARAMETER (C2= .143177157E01)
      PARAMETER (C3= .264224321E-1)
      PARAMETER (C4= .299291081E-3)
      PARAMETER (C5= .203154182E-5)
      PARAMETER (C6= .702620698E-8)
      PARAMETER (C7= .379534310E-11)
      PARAMETER (C8=-.321582393E-13)

!  Note to self ... this should be changed, somehow, in the future.
!  GHB 060806

    if(ptype.eq.1.or.ptype.eq.2.or.ptype.eq.3.or.ptype.eq.5.or.ptype.eq.6)then

      ! from Bolton (1980, MWR)
      esl=611.2 * EXP( 17.67 * ( T  - 273.15 ) / ( T  - 29.65 ) )
      rslf= eps * ESL /(P-ESL)

    elseif(ptype.eq.4)then

      rslf=380.00*exp(17.2693882-4097.8531/(t-35.86))/p

!    elseif(ptype.eq.3)then
!
!      X=MAX(-80.,T-273.16)
!      ESL=C0+X*(C1+X*(C2+X*(C3+X*(C4+X*(C5+X*(C6+X*(C7+X*C8)))))))
!      RSLF=eps*ESL/(P-ESL)

    else

      esl=611.2 * EXP( 17.67 * ( T  - 273.15 ) / ( T  - 29.65 ) )
      rslf= eps * ESL /(P-ESL)

    endif

      RETURN
      END

!
! ---------------------------------------------------------------------
! THIS FUNCTION CALCULATES THE ICE SATURATION VAPOR MIXING RATIO AS A
! FUNCTION OF TEMPERATURE AND PRESSURE
!
      FUNCTION RSIF(P,T)

      IMPLICIT NONE
      include 'input.incl'
      include 'constants.incl'
      REAL ESI,RSIF,X,T,P,C0,C1,C2,C3,C4,C5,C6,C7,C8
      PARAMETER (C0= .609868993E03)
      PARAMETER (C1= .499320233E02)
      PARAMETER (C2= .184672631E01)
      PARAMETER (C3= .402737184E-1)
      PARAMETER (C4= .565392987E-3)
      PARAMETER (C5= .521693933E-5)
      PARAMETER (C6= .307839583E-7)
      PARAMETER (C7= .105785160E-9)
      PARAMETER (C8= .161444444E-12)

!  Note to self ... this should be changed, somehow, in the future.
!  GHB 060806

    if(ptype.eq.1.or.ptype.eq.2.or.ptype.eq.3.or.ptype.eq.5.or.ptype.eq.6)then

      ! from Tao et al (1989, MWR)
      esi=611.2 * EXP( 21.8745584 * ( T  - 273.15 ) / ( T  - 7.66 ) )
      rsif= eps * ESI /(P-ESI)

    elseif(ptype.eq.4)then

      rsif=380.00*exp(21.87455-5807.4743/(t-7.66))/p

!    elseif(ptype.eq.3)then
!
!      X=MAX(-80.,T-273.16)
!      ESI=C0+X*(C1+X*(C2+X*(C3+X*(C4+X*(C5+X*(C6+X*(C7+X*C8)))))))
!      RSIF=eps*ESI/(P-ESI)

    else

      esi=611.2 * EXP( 21.8745584 * ( T  - 273.15 ) / ( T  - 7.66 ) )
      rsif= eps * ESI /(P-ESI)

    endif

      RETURN
      END


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


! REV PROCESSED 213 LINES OF CODE. PROGRAM DONE.
      REAL FUNCTION GAMMA(X)
      implicit none
!D    DOUBLE PRECISION FUNCTION DGAMMA(X)
!----------------------------------------------------------------------
!
! THIS ROUTINE CALCULATES THE GAMMA FUNCTION FOR A REAL ARGUMENT X.
!   COMPUTATION IS BASED ON AN ALGORITHM OUTLINED IN REFERENCE 1.
!   THE PROGRAM USES RATIONAL FUNCTIONS THAT APPROXIMATE THE GAMMA
!   FUNCTION TO AT LEAST 20 SIGNIFICANT DECIMAL DIGITS.  COEFFICIENTS
!   FOR THE APPROXIMATION OVER THE INTERVAL (1,2) ARE UNPUBLISHED.
!   THOSE FOR THE APPROXIMATION FOR X .GE. 12 ARE FROM REFERENCE 2.
!   THE ACCURACY ACHIEVED DEPENDS ON THE ARITHMETIC SYSTEM, THE
!   COMPILER, THE INTRINSIC FUNCTIONS, AND PROPER SELECTION OF THE
!   MACHINE-DEPENDENT CONSTANTS.
!
!
!*******************************************************************
!*******************************************************************
!
! EXPLANATION OF MACHINE-DEPENDENT CONSTANTS
!
! BETA   - RADIX FOR THE FLOATING-POINT REPRESENTATION
! MAXEXP - THE SMALLEST POSITIVE POWER OF BETA THAT OVERFLOWS
! XBIG   - THE LARGEST ARGUMENT FOR WHICH GAMMA(X) IS REPRESENTABLE
!          IN THE MACHINE, I.E., THE SOLUTION TO THE EQUATION
!                  GAMMA(XBIG) = BETA**MAXEXP
! XINF   - THE LARGEST MACHINE REPRESENTABLE FLOATING-POINT NUMBER;
!          APPROXIMATELY BETA**MAXEXP
! EPS    - THE SMALLEST POSITIVE FLOATING-POINT NUMBER SUCH THAT
!          1.0+EPS .GT. 1.0
! XMININ - THE SMALLEST POSITIVE FLOATING-POINT NUMBER SUCH THAT
!          1/XMININ IS MACHINE REPRESENTABLE
!
!     APPROXIMATE VALUES FOR SOME IMPORTANT MACHINES ARE:
!
!                            BETA       MAXEXP        XBIG
!
! CRAY-1         (S.P.)        2         8191        966.961
! CYBER 180/855
!   UNDER NOS    (S.P.)        2         1070        177.803
! IEEE (IBM/XT,
!   SUN, ETC.)   (S.P.)        2          128        35.040
! IEEE (IBM/XT,
!   SUN, ETC.)   (D.P.)        2         1024        171.624
! IBM 3033       (D.P.)       16           63        57.574
! VAX D-FORMAT   (D.P.)        2          127        34.844
! VAX G-FORMAT   (D.P.)        2         1023        171.489
!
!                            XINF         EPS        XMININ
!
! CRAY-1         (S.P.)   5.45E+2465   7.11E-15    1.84E-2466
! CYBER 180/855
!   UNDER NOS    (S.P.)   1.26E+322    3.55E-15    3.14E-294
! IEEE (IBM/XT,
!   SUN, ETC.)   (S.P.)   3.40E+38     1.19E-7     1.18E-38
! IEEE (IBM/XT,
!   SUN, ETC.)   (D.P.)   1.79D+308    2.22D-16    2.23D-308
! IBM 3033       (D.P.)   7.23D+75     2.22D-16    1.39D-76
! VAX D-FORMAT   (D.P.)   1.70D+38     1.39D-17    5.88D-39
! VAX G-FORMAT   (D.P.)   8.98D+307    1.11D-16    1.12D-308
!
!*******************************************************************
!*******************************************************************
!
! ERROR RETURNS
!
!  THE PROGRAM RETURNS THE VALUE XINF FOR SINGULARITIES OR
!     WHEN OVERFLOW WOULD OCCUR.  THE COMPUTATION IS BELIEVED
!     TO BE FREE OF UNDERFLOW AND OVERFLOW.
!
!
!  INTRINSIC FUNCTIONS REQUIRED ARE:
!
!     INT, DBLE, EXP, LOG, REAL, SIN
!
!
! REFERENCES:  AN OVERVIEW OF SOFTWARE DEVELOPMENT FOR SPECIAL
!              FUNCTIONS   W. J. CODY, LECTURE NOTES IN MATHEMATICS,
!              506, NUMERICAL ANALYSIS DUNDEE, 1975, G. A. WATSON
!              (ED.), SPRINGER VERLAG, BERLIN, 1976.
!
!              COMPUTER APPROXIMATIONS, HART, ET. AL., WILEY AND
!              SONS, NEW YORK, 1968.
!
!  LATEST MODIFICATION: OCTOBER 12, 1989
!
!  AUTHORS: W. J. CODY AND L. STOLTZ
!           APPLIED MATHEMATICS DIVISION
!           ARGONNE NATIONAL LABORATORY
!           ARGONNE, IL 60439
!
!----------------------------------------------------------------------
      INTEGER I,N
      LOGICAL PARITY
      REAL               &
!D    DOUBLE PRECISION   &
          C,CONV,EPS,FACT,HALF,ONE,P,PI,Q,RES,SQRTPI,SUM,TWELVE,   &
          TWO,X,XBIG,XDEN,XINF,XMININ,XNUM,Y,Y1,YSQ,Z,ZERO
      DIMENSION C(7),P(8),Q(8)
!----------------------------------------------------------------------
!  MATHEMATICAL CONSTANTS
!----------------------------------------------------------------------
      DATA ONE,HALF,TWELVE,TWO,ZERO/1.0E0,0.5E0,12.0E0,2.0E0,0.0E0/,   &
           SQRTPI/0.9189385332046727417803297E0/,                      &
           PI/3.1415926535897932384626434E0/
!D    DATA ONE,HALF,TWELVE,TWO,ZERO/1.0D0,0.5D0,12.0D0,2.0D0,0.0D0/,
!D   1     SQRTPI/0.9189385332046727417803297D0/,
!D   2     PI/3.1415926535897932384626434D0/
!----------------------------------------------------------------------
!  MACHINE DEPENDENT PARAMETERS
!----------------------------------------------------------------------
      DATA XBIG,XMININ,EPS/35.040E0,1.18E-38,1.19E-7/,   &
           XINF/3.4E38/
!D    DATA XBIG,XMININ,EPS/171.624D0,2.23D-308,2.22D-16/,
!D   1     XINF/1.79D308/
!----------------------------------------------------------------------
!  NUMERATOR AND DENOMINATOR COEFFICIENTS FOR RATIONAL MINIMAX
!     APPROXIMATION OVER (1,2).
!----------------------------------------------------------------------
      DATA P/-1.71618513886549492533811E+0,2.47656508055759199108314E+1,   &
             -3.79804256470945635097577E+2,6.29331155312818442661052E+2,   &
             8.66966202790413211295064E+2,-3.14512729688483675254357E+4,   &
             -3.61444134186911729807069E+4,6.64561438202405440627855E+4/
      DATA Q/-3.08402300119738975254353E+1,3.15350626979604161529144E+2,   &
            -1.01515636749021914166146E+3,-3.10777167157231109440444E+3,   &
              2.25381184209801510330112E+4,4.75584627752788110767815E+3,   &
            -1.34659959864969306392456E+5,-1.15132259675553483497211E+5/
!D    DATA P/-1.71618513886549492533811D+0,2.47656508055759199108314D+1,
!D   1       -3.79804256470945635097577D+2,6.29331155312818442661052D+2,
!D   2       8.66966202790413211295064D+2,-3.14512729688483675254357D+4,
!D   3       -3.61444134186911729807069D+4,6.64561438202405440627855D+4/
!D    DATA Q/-3.08402300119738975254353D+1,3.15350626979604161529144D+2,
!D   1      -1.01515636749021914166146D+3,-3.10777167157231109440444D+3,
!D   2        2.25381184209801510330112D+4,4.75584627752788110767815D+3,
!D   3      -1.34659959864969306392456D+5,-1.15132259675553483497211D+5/
!----------------------------------------------------------------------
!  COEFFICIENTS FOR MINIMAX APPROXIMATION OVER (12, INF).
!----------------------------------------------------------------------
      DATA C/-1.910444077728E-03,8.4171387781295E-04,                     &
           -5.952379913043012E-04,7.93650793500350248E-04,                &
           -2.777777777777681622553E-03,8.333333333333333331554247E-02,   &
            5.7083835261E-03/
!D    DATA C/-1.910444077728D-03,8.4171387781295D-04,
!D   1     -5.952379913043012D-04,7.93650793500350248D-04,
!D   2     -2.777777777777681622553D-03,8.333333333333333331554247D-02,
!D   3      5.7083835261D-03/
!----------------------------------------------------------------------
!  STATEMENT FUNCTIONS FOR CONVERSION BETWEEN INTEGER AND FLOAT
!----------------------------------------------------------------------
      CONV(I) = REAL(I)
!D    CONV(I) = DBLE(I)
      PARITY=.FALSE.
      FACT=ONE
      N=0
      Y=X
      IF(Y.LE.ZERO)THEN
!----------------------------------------------------------------------
!  ARGUMENT IS NEGATIVE
!----------------------------------------------------------------------
        Y=-X
        Y1=AINT(Y)
        RES=Y-Y1
        IF(RES.NE.ZERO)THEN
          IF(Y1.NE.AINT(Y1*HALF)*TWO)PARITY=.TRUE.
          FACT=-PI/SIN(PI*RES)
          Y=Y+ONE
        ELSE
          RES=XINF
          GOTO 900
        ENDIF
      ENDIF
!----------------------------------------------------------------------
!  ARGUMENT IS POSITIVE
!----------------------------------------------------------------------
      IF(Y.LT.EPS)THEN
!----------------------------------------------------------------------
!  ARGUMENT .LT. EPS
!----------------------------------------------------------------------
        IF(Y.GE.XMININ)THEN
          RES=ONE/Y
        ELSE
          RES=XINF
          GOTO 900
        ENDIF
      ELSEIF(Y.LT.TWELVE)THEN
        Y1=Y
        IF(Y.LT.ONE)THEN
!----------------------------------------------------------------------
!  0.0 .LT. ARGUMENT .LT. 1.0
!----------------------------------------------------------------------
          Z=Y
          Y=Y+ONE
        ELSE
!----------------------------------------------------------------------
!  1.0 .LT. ARGUMENT .LT. 12.0, REDUCE ARGUMENT IF NECESSARY
!----------------------------------------------------------------------
          N=INT(Y)-1
          Y=Y-CONV(N)
          Z=Y-ONE
        ENDIF
!----------------------------------------------------------------------
!  EVALUATE APPROXIMATION FOR 1.0 .LT. ARGUMENT .LT. 2.0
!----------------------------------------------------------------------
        XNUM=ZERO
        XDEN=ONE
        DO 260 I=1,8
          XNUM=(XNUM+P(I))*Z
          XDEN=XDEN*Z+Q(I)
  260   CONTINUE
        RES=XNUM/XDEN+ONE
        IF(Y1.LT.Y)THEN
!----------------------------------------------------------------------
!  ADJUST RESULT FOR CASE  0.0 .LT. ARGUMENT .LT. 1.0
!----------------------------------------------------------------------
          RES=RES/Y1
        ELSEIF(Y1.GT.Y)THEN
!----------------------------------------------------------------------
!  ADJUST RESULT FOR CASE  2.0 .LT. ARGUMENT .LT. 12.0
!----------------------------------------------------------------------
          DO 290 I=1,N
            RES=RES*Y
            Y=Y+ONE
  290     CONTINUE
        ENDIF
      ELSE
!----------------------------------------------------------------------
!  EVALUATE FOR ARGUMENT .GE. 12.0,
!----------------------------------------------------------------------
        IF(Y.LE.XBIG)THEN
          YSQ=Y*Y
          SUM=C(7)
          DO 350 I=1,6
            SUM=SUM/YSQ+C(I)
  350     CONTINUE
          SUM=SUM/Y-Y+SQRTPI
          SUM=SUM+(Y-HALF)*LOG(Y)
          RES=EXP(SUM)
        ELSE
          RES=XINF
          GOTO 900
        ENDIF
      ENDIF
!----------------------------------------------------------------------
!  FINAL ADJUSTMENTS AND RETURN
!----------------------------------------------------------------------
      IF(PARITY)RES=-RES
      IF(FACT.NE.ONE)RES=FACT/RES
  900 GAMMA=RES
!D900 DGAMMA = RES
      RETURN
! ---------- LAST LINE OF GAMMA ----------
      END


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      function mytime()
      implicit none

      include 'timestat.incl'

      integer count,rate,max
      real time_current,rcount

!----------------------------------------------------------
!  Platform-independent timer

      call system_clock(count,rate,max)
      if( count.lt.count_last )then
        ! simple kludge ... do nothing
        ! fix some other day   (GHB, 101018)
!!!        rcount = float(count+max)
!!!        time_current=rcount*clock_rate
!!!        mytime=time_current-time_last
!!!        rcount = float(count)
!!!        time_current=rcount*clock_rate
        rcount = float(count)
        time_current=rcount*clock_rate
        mytime=0.0
      else
        rcount = float(count)
        time_current=rcount*clock_rate
        mytime=time_current-time_last
      endif
      time_last=time_current
      count_last=count

!----------------------------------------------------------

      return
      end


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine stopcm1()
      implicit none


      stop

      end subroutine stopcm1


