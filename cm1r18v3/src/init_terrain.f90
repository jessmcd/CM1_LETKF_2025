
      subroutine init_terrain(xh,uh,xf,uf,yh,vh,yf,vf,rds,sigma,rdsf,sigmaf,  &
                              zh,zf,zs,gz,rgz,gzu,rgzu,gzv,rgzv,         &
                              dzdx,dzdy,gx,gxu,gy,gyv,                   &
                              reqs_u,reqs_v,reqs_s,reqs_p,               &
                              nw1,nw2,ne1,ne2,sw1,sw2,se1,se2,           &
                              sw31,sw32,se31,se32,ss31,ss32,sn31,sn32,   &
                              uw31,uw32,ue31,ue32,us31,us32,un31,un32,   &
                              vw31,vw32,ve31,ve32,vs31,vs32,vn31,vn32,   &
                              west,newwest,east,neweast,                 &
                              south,newsouth,north,newnorth)
      implicit none

      include 'input.incl'
      include 'constants.incl'

      real, intent(in), dimension(ib:ie) :: xh,uh
      real, intent(in), dimension(ib:ie+1) :: xf,uf
      real, intent(in), dimension(jb:je) :: yh,vh
      real, intent(in), dimension(jb:je+1) :: yf,vf
      real, intent(inout), dimension(kb:ke) :: rds,sigma
      real, intent(inout), dimension(kb:ke+1) :: rdsf,sigmaf
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: zh
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke+1) :: zf
      real, intent(inout), dimension(ib:ie,jb:je) :: zs
      real, intent(inout), dimension(itb:ite,jtb:jte) :: gz,rgz,gzu,rgzu,gzv,rgzv,dzdx,dzdy
      real, intent(inout), dimension(itb:ite,jtb:jte,ktb:kte) :: gx,gxu,gy,gyv
      integer, intent(inout), dimension(rmp) :: reqs_u,reqs_v,reqs_s,reqs_p
      real, intent(inout), dimension(kmt) :: nw1,nw2,ne1,ne2,sw1,sw2,se1,se2
      real, intent(inout), dimension(cmp,jmp,kmp)   :: sw31,sw32,se31,se32
      real, intent(inout), dimension(imp,cmp,kmp)   :: ss31,ss32,sn31,sn32
      real, intent(inout), dimension(cmp,jmp,kmp)   :: uw31,uw32,ue31,ue32
      real, intent(inout), dimension(imp+1,cmp,kmp) :: us31,us32,un31,un32
      real, intent(inout), dimension(cmp,jmp+1,kmp) :: vw31,vw32,ve31,ve32
      real, intent(inout), dimension(imp,cmp,kmp)   :: vs31,vs32,vn31,vn32
      real, intent(inout), dimension(cmp,jmp) :: west,newwest,east,neweast
      real, intent(inout), dimension(imp,cmp) :: south,newsouth,north,newnorth

      integer :: i,j,k,irec
      real :: hh,aa,xval,xc,yc
      real :: tem1,tem2,rr,angle


!-----------------------------------------------------------------------
!     SPECIFY TERRAIN HERE
!-----------------------------------------------------------------------

!----------------------------------------------------------
!  itern = 1
!  bell-shaped

        IF(itern.eq.1)THEN

          hh =      400.0              ! max. height (m)
          aa =     1000.0              ! half width (m)
          xc =        0.0 + 0.5*dx     ! x-location (m)

          do j=jb,je
          do i=ib,ie
            zs(i,j)=hh/( 1.0+( (xh(i)-xc)/aa )**2 )
          enddo
          enddo

!---------------
!  itern = 2
!  Schaer case

        ELSEIF(itern.eq.2)THEN

          do j=jb,je
          do i=ib,ie
            xval=dx*(i-ni/2)
            zs(i,j)=250.0*exp(-(xval/5000.0)**2)*(cos(pi*xval/4000.0)**2)
          enddo
          enddo

!---------------

        ELSEIF(itern.eq.3)THEN

          hh =      500.0     ! max. height (m)
          aa =    20000.0     ! half width (m)

          do j=jb,je
          do i=ib,ie
            xval = sqrt( (xh(i)-129000.0)**2   &
                        +(yh(j)-129000.0)**2   &
                                             )
            zs(i,j)=hh*( (1.0+(xval/aa)**2 )**(-1.5) )
          enddo
          enddo

!----------------------------------------------------------
!  itern = 4
!  read from GrADS file "perts.dat"

        ELSEIF(itern.eq.4)THEN

          open(unit=73,file='perts.dat',status='old',   &
               form='unformatted',access='direct',recl=4)

          do j=1,nj
          do i=1,ni
            irec=(myj-1)*nx*nj   &
                +(j-1)*nx        &
                +(myi-1)*ni      &
                +i
            read(73,rec=irec) zs(i,j)
          enddo
          enddo

          close(unit=73)

!----------------------------------------------------------

        ENDIF

!--------------------------------------------------------------
!  DO NOT CHANGE ANYTHING BELOW HERE !
!--------------------------------------------------------------

        call bc2d(zs)

        zt = maxz
        rzt = 1.0/maxz

        if(dowr) write(outfile,*)
        do k=1,nk+1
          if(dowr) write(outfile,*) '  sigmaf:',k,sigmaf(k)
        enddo
        if(dowr) write(outfile,*)

        do k=1,nk
        do j=jb,je
        do i=ib,ie
          zh(i,j,k)=zs(i,j)+sigma(k)*(zt-zs(i,j))/zt
        enddo
        enddo
        enddo

        do k=kb,ke+1
        do j=jb,je
        do i=ib,ie
          zf(i,j,k)=zs(i,j)+sigmaf(k)*(zt-zs(i,j))/zt
        enddo
        enddo
        enddo

        do j=1,nj
        do i=1,ni
          dzdx(i,j)=( 45.0*( zs(i+1,j)-zs(i-1,j) )                &
                      -9.0*( zs(i+2,j)-zs(i-2,j) )                &
                          +( zs(i+3,j)-zs(i-3,j) ) )*uh(i)/(60.0*dx)
          dzdy(i,j)=( 45.0*( zs(i,j+1)-zs(i,j-1) )                &
                      -9.0*( zs(i,j+2)-zs(i,j-2) )                &
                          +( zs(i,j+3)-zs(i,j-3) ) )*vh(j)/(60.0*dy)
        enddo
        enddo

!--------------------------------
!  set boundary points

        call bc2d(dzdx)
        call bc2d(dzdy)


!--------------------------------
!  the metric terms:

        do j=jb,je
        do i=ib,ie
           gz(i,j)=zt/(zt-zs(i,j))
          rgz(i,j)=(zt-zs(i,j))/zt
        enddo
        enddo

        call bc2d(rgz)

        do j=jb+1,je
        do i=ib+1,ie
           gzu(i,j)=zt/(zt-0.5*(zs(i-1,j)+zs(i,j)))
          rgzu(i,j)=(zt-0.5*(zs(i-1,j)+zs(i,j)))/zt
           gzv(i,j)=zt/(zt-0.5*(zs(i,j-1)+zs(i,j)))
          rgzv(i,j)=(zt-0.5*(zs(i,j-1)+zs(i,j)))/zt
        enddo
        enddo

        do k=1,nk+1
        do j=jb+1,je-1
        do i=ib+1,ie-1
          gx(i,j,k)=(zt-sigmaf(k))*gz(i,j)*(rgzu(i+1,j)-rgzu(i,j))*rdx*uh(i)
          gxu(i,j,k)=(zt-sigmaf(k))*gzu(i,j)*(rgz(i,j)-rgz(i-1,j))*rdx*uf(i)
          gy(i,j,k)=(zt-sigmaf(k))*gz(i,j)*(rgzv(i,j+1)-rgzv(i,j))*rdy*vh(j)
          gyv(i,j,k)=(zt-sigmaf(k))*gzv(i,j)*(rgz(i,j)-rgz(i,j-1))*rdy*vf(j)
        enddo
        enddo
        enddo

!--------------------------------

        do j=jb,je
        do i=ib,ie
          zf(i,j,0)=zf(i,j,1)-(zf(i,j,2)-zf(i,j,1))
          zf(i,j,nk+2)=zf(i,j,nk+1)+(zf(i,j,nk+1)-zf(i,j,nk))
          zh(i,j,0)=0.5*(zf(i,j,0)+zf(i,j,1))
          zh(i,j,nk+1)=0.5*(zf(i,j,nk+1)+zf(i,j,nk+2))
        enddo
        enddo

        if(dowr) write(outfile,*)
        do i=ib,ie
          if(dowr) write(outfile,*) '  zs at nj/2:',i,zs(i,nj/2)
        enddo
        if(dowr) write(outfile,*)

        if(dowr) write(outfile,*)
        do j=jb,je
          if(dowr) write(outfile,*) '  zs at ni/2:',j,zs(ni/2,j)
        enddo
        if(dowr) write(outfile,*)

!---------------------------------------

      do k=2,nk
        rds(k) = 1.0/(sigma(k)-sigma(k-1))
      enddo

      do k=1,nk
        rdsf(k) = 1.0/(sigmaf(k+1)-sigmaf(k))
      enddo

!-----------------------------------------------------------------------

      end subroutine init_terrain

