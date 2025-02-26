

      program cm1

      use module_restart
      implicit none

!-----------------------------------------------------------------------
!
!  CM1 Numerical Model, Release 18.3  (cm1r18.3)
!  7 October 2015
!  http://www2.mmm.ucar.edu/people/bryan/cm1/
!
!  Copyright (c) 2000-2015 by George H. Bryan, National Center for 
!  Atmospheric Research, Boulder, Colorado, USA.  
!
!-----------------------------------------------------------------------
!
!  Please see documentation at the top of the "solve.F" file.
!
!  See also documentation at the cm1 website, such as:
!
!    "The governing equations for CM1"
!        http://www2.mmm.ucar.edu/people/bryan/cm1/cm1_equations.pdf
!
!-----------------------------------------------------------------------

      include 'input.incl'
      include 'radcst.incl'
      include 'constants.incl'
      include 'timestat.incl'

      integer :: nstep,nstep0
      integer :: nrec,prec,nwrite,nrst
      integer :: rbufsz,num_soil_layers,ndt,ntdiag,nqdiag
      real :: dt,dtlast
      double precision :: mtime,stattim,taptim,rsttim,radtim,prcltim
      double precision :: adt,acfl,dbldt
      double precision :: mass1,mass2
      logical :: dosfcflx
      logical, dimension(maxq) :: cloudvar,rhovar
      character*15 :: tdef
      character*3, dimension(maxq) :: qname
      character*6, dimension(maxq) :: budname
      double precision, dimension(:), allocatable :: bud,bud2
      double precision, dimension(:), allocatable :: qbudget
      double precision, dimension(:), allocatable :: asq,bsq
      real, dimension(:), allocatable :: xh,rxh,arh1,arh2,uh,ruh
      real, dimension(:), allocatable :: xf,rxf,arf1,arf2,uf,ruf
      real, dimension(:), allocatable :: yh,vh,rvh
      real, dimension(:), allocatable :: yf,vf,rvf
      real, dimension(:), allocatable :: xfref,yfref
      double precision, dimension(:), allocatable :: dumk1,dumk2
      real, dimension(:), allocatable :: rds,sigma,rdsf,sigmaf
      real, dimension(:,:,:), allocatable :: tauh,taus,zh,mh,rmh,c1,c2
      real, dimension(:,:,:), allocatable :: tauf,zf,mf,rmf
      real, dimension(:), allocatable :: rstat
      real, dimension(:,:), allocatable :: rho0s,pi0s,prs0s,rth0s
      real, dimension(:,:,:), allocatable :: pi0,rho0,prs0,thv0,th0,rth0,qv0
      real, dimension(:,:,:), allocatable :: qc0,qi0,rr0,rf0,rrf0,u0,v0
      real, dimension(:,:,:), allocatable :: dum1,dum2,dum3,dum4,dum5,dum6,dum7,dum8
      real, dimension(:,:), allocatable :: zs,gz,rgz,gzu,rgzu,gzv,rgzv,dzdx,dzdy
      real, dimension(:,:,:), allocatable :: gx,gxu,gy,gyv
      real, dimension(:,:,:), allocatable :: rain,sws,svs,sps,srs,sgs,sus,shs
      real, dimension(:,:), allocatable :: tsk,znt,ust,thflux,qvflux,cd,ch,cq,u1,v1,s1,xland,psfc,tlh
      real, dimension(:,:), allocatable :: radbcw,radbce
      real, dimension(:,:), allocatable :: radbcs,radbcn
      real, dimension(:,:,:), allocatable :: divx,rho,rr,rf,prs
      real, dimension(:,:,:), allocatable :: t11,t12,t13,t22,t23,t33
      real, dimension(:,:,:), allocatable :: rru,us,ua,u3d,uten,uten1
      real, dimension(:,:,:), allocatable :: rrv,vs,va,v3d,vten,vten1
      real, dimension(:,:,:), allocatable :: rrw,ws,wa,w3d,wten,wten1
      real, dimension(:,:,:), allocatable :: ppi,pp3d,piadv,ppten,sten,ppx
      real, dimension(:,:,:), allocatable :: tha,th3d,thadv,thten,thten1,thterm
      real, dimension(:,:,:), allocatable :: qpten,qtten,qvten,qcten
      real, dimension(:,:,:,:), allocatable :: qa,q3d,qten
      real, dimension(:,:,:), allocatable :: kmh,kmv,khh,khv
      real, dimension(:,:,:), allocatable :: tkea,tke3d,tketen
      real, dimension(:,:,:), allocatable :: nm,defv,defh,dissten
      real, dimension(:,:,:), allocatable :: thpten,qvpten,qcpten,qipten,upten,vpten
      real, dimension(:,:,:), allocatable :: swten,lwten,o30
      real, dimension(:,:), allocatable :: radsw,rnflx,radswnet,radlwin,dsr,olr
      real, dimension(:,:,:), allocatable :: rad2d,effc,effi,effs,effr,effg,effis
      integer, dimension(:,:), allocatable :: lu_index,kpbl2d
      real, dimension(:,:), allocatable :: u10,v10,s10,hfx,qfx,               &
                                      hpbl,wspd,psim,psih,gz1oz0,br,          &
                                      CHS,CHS2,CQS2,CPMM,ZOL,MAVAIL,          &
                                      MOL,RMOL,REGIME,LH,FLHC,FLQC,QGH,       &
                                      CK,CKA,CDA,USTM,QSFC,T2,Q2,TH2,EMISS,THC,ALBD,   &
                                      f2d,gsw,glw,chklowq,capg,snowc,dsxy,wstar,delta,fm,fh
      real, dimension(:,:), allocatable :: mznt,smois,taux,tauy,hpbl2d,evap2d,heat2d,rc2d
      real, dimension(:), allocatable :: slab_zs,slab_dzs
      real, dimension(:,:,:), allocatable :: tslb
      real, dimension(:,:), allocatable :: tmn,tml,t0ml,hml,h0ml,huml,hvml,tmoml
      real, dimension(:,:,:,:),  allocatable :: pta,pt3d,ptten
      real, dimension(:,:), allocatable :: dat1,dat2
      real, dimension(:,:,:), allocatable :: dat3
      integer, dimension(:), allocatable :: reqt
      real, dimension(:,:), allocatable :: pdata,packet,ploc
      logical, dimension(:,:,:), allocatable :: flag

!--- arrays for MPI ---
      integer, dimension(:), allocatable :: reqs_u,reqs_v,reqs_w,reqs_s,reqs_p,reqs_tk
      integer, dimension(:,:),  allocatable :: reqs_q,reqs_t
      real, dimension(:), allocatable :: nw1,nw2,ne1,ne2,sw1,sw2,se1,se2
      real, dimension(:,:,:), allocatable :: n3w1,n3w2,n3e1,n3e2,s3w1,s3w2,s3e1,s3e2
      real, dimension(:,:), allocatable :: ww1,ww2,we1,we2
      real, dimension(:,:), allocatable :: ws1,ws2,wn1,wn2
      real, dimension(:,:), allocatable :: pw1,pw2,pe1,pe2
      real, dimension(:,:), allocatable :: ps1,ps2,pn1,pn2
      real, dimension(:,:), allocatable :: vw1,vw2,ve1,ve2
      real, dimension(:,:), allocatable :: vs1,vs2,vn1,vn2
      real, dimension(:,:,:), allocatable :: uw31,uw32,ue31,ue32
      real, dimension(:,:,:), allocatable :: us31,us32,un31,un32
      real, dimension(:,:,:), allocatable :: vw31,vw32,ve31,ve32
      real, dimension(:,:,:), allocatable :: vs31,vs32,vn31,vn32
      real, dimension(:,:,:), allocatable :: ww31,ww32,we31,we32
      real, dimension(:,:,:), allocatable :: ws31,ws32,wn31,wn32
      real, dimension(:,:,:), allocatable :: sw31,sw32,se31,se32
      real, dimension(:,:,:), allocatable :: ss31,ss32,sn31,sn32
      real, dimension(:,:,:,:), allocatable :: rw31,rw32,re31,re32
      real, dimension(:,:,:,:), allocatable :: rs31,rs32,rn31,rn32
      real, dimension(:,:,:,:), allocatable :: qw31,qw32,qe31,qe32
      real, dimension(:,:,:,:), allocatable :: qs31,qs32,qn31,qn32
      real, dimension(:,:,:), allocatable :: tkw1,tkw2,tke1,tke2
      real, dimension(:,:,:), allocatable :: tks1,tks2,tkn1,tkn2
      real, dimension(:,:,:), allocatable :: kw1,kw2,ke1,ke2
      real, dimension(:,:,:), allocatable :: ks1,ks2,kn1,kn2
      real, dimension(:,:,:,:), allocatable :: tw1,tw2,te1,te2
      real, dimension(:,:,:,:), allocatable :: ts1,ts2,tn1,tn2

      ! arrays for elliptic solver:
      real, dimension(:,:,:),    allocatable :: cfb
      real, dimension(:),        allocatable :: cfa,cfc,d1,d2
      complex, dimension(:,:,:), allocatable :: pdt,deft
      complex, dimension(:,:),   allocatable :: rhs,trans

      ! diagnostic arrays:
      real, dimension(:,:,:,:), allocatable :: tdiag,qdiag

!-----

      integer count,rate,maxr
      real rtime,xtime,time_solve,time_solve0
      real steptime1,steptime2
      integer :: i,j,k,n,nn,fnum
      real :: sum,tem0
      logical :: getsfc,restart,restart_prcl,reset

      namelist /param0/ nx,ny,nz,nodex,nodey,ppnode,timeformat,timestats,terrain_flag,procfiles

!----------------------------------------------------------------------

      nstep = 0
      nstep0 = 0
      mtime = 0.0d0
      nrec=1
      prec=1
      nwrite=1
      nrst=0
      outfile=6
      stopit = .false.
      smeps = 1.0e-30
      tsmall = 0.0001
      ! (should be same as qsmall in morrison scheme)
      qsmall = 1.0e-14
      ndt = 0
      adt = 0.0
      acfl = 0.0
      mass1 = 0.0
      mass2 = 0.0
      ntdiag = 1
      nqdiag = 1
      getsfc = .true.
      restart = .false.
      restart_prcl = .false.
      restart_format = 1
      restart_filetype = 1
      restart_reset_frqtim = .true.
      run_time = -999.0

!----------------------------------------------------------------------
!  Initialize MPI

      myid=0
      numprocs=1


!----------------------------------------------------------------------
!  Get domain dimensions, allocate some arrays, then call PARAM

      open(unit=20,file='namelist.input',form='formatted',status='old',    &
           access='sequential',err=8888)
      read(20,nml=param0,err=8888,end=8888)
      close(unit=20)

      IF( procfiles )THEN
        dowr = .true.
      ELSE
        dowr = .false.
      ENDIF

      IF( myid.eq.0 ) dowr = .true.

      nodex  = max(1,nodex)
      nodey  = max(1,nodey)
      ppnode = max(1,ppnode)

      ! serial (i.e. single-processor) run:
      nodex = 1
      nodey = 1
      ppnode = 1

      ni = nx / nodex
      nj = ny / nodey
      nk = nz
      nkp1 = nk+1

      ! (The following are needed by ZVD, but are also included for future 
      !  development, e.g., possible distributed-memory decomposition in 
      !  z direction)
      !
      ! number of 'ghost' points in the horizontal directions:
      ngxy  = 3
      ! number of 'ghost' points in the vertical direction:
      ngz   = 1

!---------------------------------------------------------------------
!      For ZVD:
!      ngz   = 3
!      IF( ngz.eq.3 )THEN
!        kb =  1 - ngz
!        ke = nk + ngz
!      ENDIF
!---------------------------------------------------------------------

      ib =  1 - ngxy
      ie = ni + ngxy
      jb =  1 - ngxy
      je = nj + ngxy
      kb =  1 - ngz
      ke = nk + ngz

      allocate(    xh(ib:ie) )
      xh = 0.0
      allocate(   rxh(ib:ie) )
      rxh = 0.0
      allocate(  arh1(ib:ie) )
      arh1 = 0.0
      allocate(  arh2(ib:ie) )
      arh2 = 0.0
      allocate(    uh(ib:ie) )
      uh = 0.0
      allocate(   ruh(ib:ie) )
      ruh = 0.0
      allocate(    xf(ib:ie+1) )
      xf = 0.0
      allocate(   rxf(ib:ie+1) )
      rxf = 0.0
      allocate(  arf1(ib:ie+1) )
      arf1 = 0.0
      allocate(  arf2(ib:ie+1) )
      arf2 = 0.0
      allocate(    uf(ib:ie+1) )
      uf = 0.0
      allocate(   ruf(ib:ie+1) )
      ruf = 0.0
      allocate(    yh(jb:je) )
      yh = 0.0
      allocate(    vh(jb:je) )
      vh = 0.0
      allocate(   rvh(jb:je) )
      rvh = 0.0
      allocate(    yf(jb:je+1) )
      yf = 0.0
      allocate(    vf(jb:je+1) )
      vf = 0.0
      allocate(   rvf(jb:je+1) )
      rvf = 0.0
      allocate( xfref(-2:nx+4) )
      xfref = 0.0
      allocate( yfref(-2:ny+4) )
      yfref = 0.0
      allocate( dumk1(kb:ke) )
      dumk1 = 0.0
      allocate( dumk2(kb:ke) )
      dumk2 = 0.0
      allocate(   rds(kb:ke) )
      rds = 0.0
      allocate( sigma(kb:ke) )
      sigma = 0.0
      allocate(   rdsf(kb:ke+1) )
      rdsf = 0.0
      allocate( sigmaf(kb:ke+1) )
      sigmaf = 0.0
      allocate(  tauh(ib:ie,jb:je,kb:ke) )
      tauh = 0.0
      allocate(  taus(ib:ie,jb:je,kb:ke) )
      taus = 0.0
      allocate(    zh(ib:ie,jb:je,kb:ke) )
      zh = 0.0
      allocate(    mh(ib:ie,jb:je,kb:ke) )
      mh = 0.0
      allocate(   rmh(ib:ie,jb:je,kb:ke) )
      rmh = 0.0
      allocate(    c1(ib:ie,jb:je,kb:ke) )
      c1 = 0.0
      allocate(    c2(ib:ie,jb:je,kb:ke) )
      c2 = 0.0
      allocate(  tauf(ib:ie,jb:je,kb:ke+1) )
      tauf = 0.0
      allocate(    mf(ib:ie,jb:je,kb:ke+1) )
      mf = 0.0
      allocate(   rmf(ib:ie,jb:je,kb:ke+1) )
      rmf = 0.0

      if(terrain_flag)then
        itb=ib
        ite=ie
        jtb=jb
        jte=je
        ktb=kb
        kte=ke
      else
        itb=1
        ite=1
        jtb=1
        jte=1
        ktb=1
        kte=1
      endif

      allocate(   zs(ib:ie,jb:je) )
      zs = 0.0
      allocate(   gz(itb:ite,jtb:jte) )
      gz = 0.0
      allocate(  rgz(itb:ite,jtb:jte) )
      rgz = 0.0
      allocate(  gzu(itb:ite,jtb:jte) )
      gzu = 0.0
      allocate( rgzu(itb:ite,jtb:jte) )
      rgzu = 0.0
      allocate(  gzv(itb:ite,jtb:jte) )
      gzv = 0.0
      allocate( rgzv(itb:ite,jtb:jte) )
      rgzv = 0.0
      allocate( dzdx(itb:ite,jtb:jte) )
      dzdx = 0.0
      allocate( dzdy(itb:ite,jtb:jte) )
      dzdy = 0.0
      allocate(   gx(itb:ite,jtb:jte,ktb:kte) )
      gx = 0.0
      allocate(  gxu(itb:ite,jtb:jte,ktb:kte) )
      gxu = 0.0
      allocate(   gy(itb:ite,jtb:jte,ktb:kte) )
      gy = 0.0
      allocate(  gyv(itb:ite,jtb:jte,ktb:kte) )
      gyv = 0.0
      allocate(   zf(ib:ie,jb:je,kb:ke+1) )
      zf = 0.0

!------
! allocate the MPI arrays

      imp = 1
      jmp = 1
      kmp = 2
      kmt = 2
      rmp = 1
      cmp = 1

      allocate( reqs_u(rmp) )
      reqs_u = 0
      allocate( reqs_v(rmp) )
      reqs_v = 0
      allocate( reqs_w(rmp) )
      reqs_w = 0
      allocate( reqs_s(rmp) )
      reqs_s = 0
      allocate( reqs_p(rmp) )
      reqs_p = 0
      allocate( reqs_tk(rmp) )
      reqs_tk = 0

      allocate( nw1(kmt) )
      nw1 = 0.0
      allocate( nw2(kmt) )
      nw2 = 0.0
      allocate( ne1(kmt) )
      ne1 = 0.0
      allocate( ne2(kmt) )
      ne2 = 0.0
      allocate( sw1(kmt) )
      sw1 = 0.0
      allocate( sw2(kmt) )
      sw2 = 0.0
      allocate( se1(kmt) )
      se1 = 0.0
      allocate( se2(kmt) )
      se2 = 0.0

      allocate( n3w1(cmp,cmp,kmt+1) )
      n3w1 = 0.0
      allocate( n3w2(cmp,cmp,kmt+1) )
      n3w2 = 0.0
      allocate( n3e1(cmp,cmp,kmt+1) )
      n3e1 = 0.0
      allocate( n3e2(cmp,cmp,kmt+1) )
      n3e2 = 0.0
      allocate( s3w1(cmp,cmp,kmt+1) )
      s3w1 = 0.0
      allocate( s3w2(cmp,cmp,kmt+1) )
      s3w2 = 0.0
      allocate( s3e1(cmp,cmp,kmt+1) )
      s3e1 = 0.0
      allocate( s3e2(cmp,cmp,kmt+1) )
      s3e2 = 0.0

      allocate( ww1(jmp,kmp-1) )
      ww1 = 0.0
      allocate( ww2(jmp,kmp-1) )
      ww2 = 0.0
      allocate( we1(jmp,kmp-1) )
      we1 = 0.0
      allocate( we2(jmp,kmp-1) )
      we2 = 0.0
      allocate( ws1(imp,kmp-1) )
      ws1 = 0.0
      allocate( ws2(imp,kmp-1) )
      ws2 = 0.0
      allocate( wn1(imp,kmp-1) )
      wn1 = 0.0
      allocate( wn2(imp,kmp-1) )
      wn2 = 0.0

      allocate( pw1(jmp,kmp) )
      pw1 = 0.0
      allocate( pw2(jmp,kmp) )
      pw2 = 0.0
      allocate( pe1(jmp,kmp) )
      pe1 = 0.0
      allocate( pe2(jmp,kmp) )
      pe2 = 0.0
      allocate( ps1(imp,kmp) )
      ps1 = 0.0
      allocate( ps2(imp,kmp) )
      ps2 = 0.0
      allocate( pn1(imp,kmp) )
      pn1 = 0.0
      allocate( pn2(imp,kmp) )
      pn2 = 0.0

      allocate( vw1(jmp,kmp) )
      vw1 = 0.0
      allocate( vw2(jmp,kmp) )
      vw2 = 0.0
      allocate( ve1(jmp,kmp) )
      ve1 = 0.0
      allocate( ve2(jmp,kmp) )
      ve2 = 0.0
      allocate( vs1(imp,kmp) )
      vs1 = 0.0
      allocate( vs2(imp,kmp) )
      vs2 = 0.0
      allocate( vn1(imp,kmp) )
      vn1 = 0.0
      allocate( vn2(imp,kmp) )
      vn2 = 0.0

      allocate( uw31(cmp,jmp,kmp) )
      uw31 = 0.0
      allocate( uw32(cmp,jmp,kmp) )
      uw32 = 0.0
      allocate( ue31(cmp,jmp,kmp) )
      ue31 = 0.0
      allocate( ue32(cmp,jmp,kmp) )
      ue32 = 0.0
      allocate( us31(imp+1,cmp,kmp) )
      us31 = 0.0
      allocate( us32(imp+1,cmp,kmp) )
      us32 = 0.0
      allocate( un31(imp+1,cmp,kmp) )
      un31 = 0.0
      allocate( un32(imp+1,cmp,kmp) )
      un32 = 0.0

      allocate( vw31(cmp,jmp+1,kmp) )
      vw31 = 0.0
      allocate( vw32(cmp,jmp+1,kmp) )
      vw32 = 0.0
      allocate( ve31(cmp,jmp+1,kmp) )
      ve31 = 0.0
      allocate( ve32(cmp,jmp+1,kmp) )
      ve32 = 0.0
      allocate( vs31(imp,cmp,kmp) )
      vs31 = 0.0
      allocate( vs32(imp,cmp,kmp) )
      vs32 = 0.0
      allocate( vn31(imp,cmp,kmp) )
      vn31 = 0.0
      allocate( vn32(imp,cmp,kmp) )
      vn32 = 0.0

      allocate( ww31(cmp,jmp,kmp-1) )
      ww31 = 0.0
      allocate( ww32(cmp,jmp,kmp-1) )
      ww32 = 0.0
      allocate( we31(cmp,jmp,kmp-1) )
      we31 = 0.0
      allocate( we32(cmp,jmp,kmp-1) )
      we32 = 0.0
      allocate( ws31(imp,cmp,kmp-1) )
      ws31 = 0.0
      allocate( ws32(imp,cmp,kmp-1) )
      ws32 = 0.0
      allocate( wn31(imp,cmp,kmp-1) )
      wn31 = 0.0
      allocate( wn32(imp,cmp,kmp-1) )
      wn32 = 0.0

      allocate( sw31(cmp,jmp,kmp) )
      sw31 = 0.0
      allocate( sw32(cmp,jmp,kmp) )
      sw32 = 0.0
      allocate( se31(cmp,jmp,kmp) )
      se31 = 0.0
      allocate( se32(cmp,jmp,kmp) )
      se32 = 0.0
      allocate( ss31(imp,cmp,kmp) )
      ss31 = 0.0
      allocate( ss32(imp,cmp,kmp) )
      ss32 = 0.0
      allocate( sn31(imp,cmp,kmp) )
      sn31 = 0.0
      allocate( sn32(imp,cmp,kmp) )
      sn32 = 0.0

      allocate( rw31(cmp,jmp,kmp,2) )
      rw31 = 0.0
      allocate( rw32(cmp,jmp,kmp,2) )
      rw32 = 0.0
      allocate( re31(cmp,jmp,kmp,2) )
      re31 = 0.0
      allocate( re32(cmp,jmp,kmp,2) )
      re32 = 0.0
      allocate( rs31(imp,cmp,kmp,2) )
      rs31 = 0.0
      allocate( rs32(imp,cmp,kmp,2) )
      rs32 = 0.0
      allocate( rn31(imp,cmp,kmp,2) )
      rn31 = 0.0
      allocate( rn32(imp,cmp,kmp,2) )
      rn32 = 0.0

      allocate( tkw1(cmp,jmp,kmt) )
      tkw1 = 0.0
      allocate( tkw2(cmp,jmp,kmt) )
      tkw2 = 0.0
      allocate( tke1(cmp,jmp,kmt) )
      tke1 = 0.0
      allocate( tke2(cmp,jmp,kmt) )
      tke2 = 0.0
      allocate( tks1(imp,cmp,kmt) )
      tks1 = 0.0
      allocate( tks2(imp,cmp,kmt) )
      tks2 = 0.0
      allocate( tkn1(imp,cmp,kmt) )
      tkn1 = 0.0
      allocate( tkn2(imp,cmp,kmt) )
      tkn2 = 0.0

      allocate( kw1(jmp,kmt,4) )
      kw1 = 0.0
      allocate( kw2(jmp,kmt,4) )
      kw2 = 0.0
      allocate( ke1(jmp,kmt,4) )
      ke1 = 0.0
      allocate( ke2(jmp,kmt,4) )
      ke2 = 0.0
      allocate( ks1(imp,kmt,4) )
      ks1 = 0.0
      allocate( ks2(imp,kmt,4) )
      ks2 = 0.0
      allocate( kn1(imp,kmt,4) )
      kn1 = 0.0
      allocate( kn2(imp,kmt,4) )
      kn2 = 0.0

      call param(dt,dtlast,stattim,taptim,rsttim,radtim,prcltim,  &
                 cloudvar,rhovar,qname,budname,                   &
                 xh,rxh,arh1,arh2,uh,ruh,xf,rxf,arf1,arf2,uf,ruf, &
                 yh,vh,rvh,yf,vf,rvf,xfref,yfref,                 &
                 rds,sigma,rdsf,sigmaf,tauh,taus,zh,mh,rmh,c1,c2,tauf,zf,mf,rmf, &
                 zs,gz,rgz,gzu,rgzu,gzv,rgzv,dzdx,dzdy,gx,gxu,gy,gyv, &
                 ntdiag,nqdiag,                                   &
                 reqs_u,reqs_v,reqs_s,reqs_p,                     &
                 nw1,nw2,ne1,ne2,sw1,sw2,se1,se2,                 &
                 n3w1,n3w2,n3e1,n3e2,s3w1,s3w2,s3e1,s3e2,         &
                 sw31,sw32,se31,se32,ss31,ss32,sn31,sn32,         &
                 uw31,uw32,ue31,ue32,us31,us32,un31,un32,         &
                 vw31,vw32,ve31,ve32,vs31,vs32,vn31,vn32,         &
                 ww31,ww32,we31,we32,ws31,ws32,wn31,wn32)

      dbldt = dble(dt)

      allocate( reqs_q(rmp,numq) )
      reqs_q = 0
      allocate( reqs_t(rmp,npt) )
      reqs_t = 0

      allocate( qw31(cmp,jmp,kmp,numq) )
      qw31 = 0.0
      allocate( qw32(cmp,jmp,kmp,numq) )
      qw32 = 0.0
      allocate( qe31(cmp,jmp,kmp,numq) )
      qe31 = 0.0
      allocate( qe32(cmp,jmp,kmp,numq) )
      qe32 = 0.0
      allocate( qs31(imp,cmp,kmp,numq) )
      qs31 = 0.0
      allocate( qs32(imp,cmp,kmp,numq) )
      qs32 = 0.0
      allocate( qn31(imp,cmp,kmp,numq) )
      qn31 = 0.0
      allocate( qn32(imp,cmp,kmp,numq) )
      qn32 = 0.0

      allocate( tw1(cmp,jmp,kmp,npt) )
      tw1 = 0.0
      allocate( tw2(cmp,jmp,kmp,npt) )
      tw2 = 0.0
      allocate( te1(cmp,jmp,kmp,npt) )
      te1 = 0.0
      allocate( te2(cmp,jmp,kmp,npt) )
      te2 = 0.0
      allocate( ts1(imp,cmp,kmp,npt) )
      ts1 = 0.0
      allocate( ts2(imp,cmp,kmp,npt) )
      ts2 = 0.0
      allocate( tn1(imp,cmp,kmp,npt) )
      tn1 = 0.0
      allocate( tn2(imp,cmp,kmp,npt) )
      tn2 = 0.0

!----------------------------------------------------------------------
!  allocate the base state arrays, then call BASE

      allocate( rstat(stat_out) )
      rstat = 0.0
      allocate( rho0s(ib:ie,jb:je) )
      rho0s = 0.0
      allocate(  pi0s(ib:ie,jb:je) )
      pi0s = 0.0
      allocate( prs0s(ib:ie,jb:je) )
      prs0s = 0.0
      allocate( rth0s(ib:ie,jb:je) )
      rth0s = 0.0
      allocate(  pi0(ib:ie,jb:je,kb:ke) )
      pi0 = 0.0
      allocate( rho0(ib:ie,jb:je,kb:ke) )
      rho0 = 0.0
      allocate( prs0(ib:ie,jb:je,kb:ke) )
      prs0 = 0.0
      allocate( thv0(ib:ie,jb:je,kb:ke) )
      thv0 = 0.0
      allocate(  th0(ib:ie,jb:je,kb:ke) )
      th0 = 0.0
      allocate( rth0(ib:ie,jb:je,kb:ke) )
      rth0 = 0.0
      allocate(  qv0(ib:ie,jb:je,kb:ke) )
      qv0 = 0.0
      allocate(  qc0(ib:ie,jb:je,kb:ke) )
      qc0 = 0.0
      allocate(  qi0(ib:ie,jb:je,kb:ke) )
      qi0 = 0.0
      allocate(  rr0(ib:ie,jb:je,kb:ke) )
      rr0 = 0.0
      allocate(  rf0(ib:ie,jb:je,kb:ke) )
      rf0 = 0.0
      allocate( rrf0(ib:ie,jb:je,kb:ke) )
      rrf0 = 0.0
      allocate(   u0(ib:ie+1,jb:je,kb:ke) )
      u0 = 0.0
      allocate(   v0(ib:ie,jb:je+1,kb:ke) )
      v0 = 0.0

      allocate( dum1(ib:ie,jb:je,kb:ke) )
      dum1 = 0.0
      allocate( dum2(ib:ie,jb:je,kb:ke) )
      dum2 = 0.0
      allocate( dum3(ib:ie,jb:je,kb:ke) )
      dum3 = 0.0
      allocate( dum4(ib:ie,jb:je,kb:ke) )
      dum4 = 0.0
      allocate( dum5(ib:ie,jb:je,kb:ke) )
      dum5 = 0.0
      allocate( dum6(ib:ie,jb:je,kb:ke) )
      dum6 = 0.0
      allocate( dum7(ib:ie,jb:je,kb:ke) )
      dum7 = 0.0
      allocate( dum8(ib:ie,jb:je,kb:ke) )
      dum8 = 0.0

      call base(zh,mh,c1,c2,zf,mf,rho0s,pi0s,prs0s,rth0s,             &
                pi0,prs0,rho0,thv0,th0,rth0,qv0,u0,v0,                &
                qc0,qi0,rr0,rf0,rrf0,dum1,dum2,                       &
                reqs_u,reqs_v,reqs_s,nw1,nw2,ne1,ne2,sw1,sw2,se1,se2, &
                n3w1,n3w2,n3e1,n3e2,s3w1,s3w2,s3e1,s3e2,              &
                uw31,uw32,ue31,ue32,us31,us32,un31,un32,              &
                vw31,vw32,ve31,ve32,vs31,vs32,vn31,vn32,              &
                sw31,sw32,se31,se32,ss31,ss32,sn31,sn32)

!----------------------------------------------------------------------
!  Now, allocate the mother lode, then call INIT3D

      allocate(   rain(ib:ie,jb:je,nrain) )
      rain = 0.0
      allocate(    sws(ib:ie,jb:je,nrain) )
      sws = 0.0
      allocate(    svs(ib:ie,jb:je,nrain) )
      svs = 0.0
      allocate(    sps(ib:ie,jb:je,nrain) )
      sps = 0.0
      allocate(    srs(ib:ie,jb:je,nrain) )
      srs = 0.0
      allocate(    sgs(ib:ie,jb:je,nrain) )
      sgs = 0.0
      allocate(    sus(ib:ie,jb:je,nrain) )
      sus = 0.0
      allocate(    shs(ib:ie,jb:je,nrain) )
      shs = 0.0

      allocate(    tsk(ib:ie,jb:je) )
      tsk = 0.0
      allocate(    znt(ib:ie,jb:je) )
      znt = 0.0
      allocate(    ust(ib:ie,jb:je) )
      ust = 0.0
      allocate( thflux(ib:ie,jb:je) )
      thflux = 0.0
      allocate( qvflux(ib:ie,jb:je) )
      qvflux = 0.0
      allocate(     cd(ib:ie,jb:je) )
      cd = 0.0
      allocate(     ch(ib:ie,jb:je) )
      ch = 0.0
      allocate(     cq(ib:ie,jb:je) )
      cq = 0.0
      allocate(     u1(ib:ie,jb:je) )
      u1 = 0.0
      allocate(     v1(ib:ie,jb:je) )
      v1 = 0.0
      allocate(     s1(ib:ie,jb:je) )
      s1 = 0.0
      allocate(  xland(ib:ie,jb:je) )
      xland = 0.0
      allocate(   psfc(ib:ie,jb:je) )
      psfc = 0.0
      allocate(    tlh(ib:ie,jb:je) )
      tlh = l_h

      allocate( radbcw(jb:je,kb:ke) )
      radbcw = 0.0
      allocate( radbce(jb:je,kb:ke) )
      radbce = 0.0
      allocate( radbcs(ib:ie,kb:ke) )
      radbcs = 0.0
      allocate( radbcn(ib:ie,kb:ke) )
      radbcn = 0.0

      allocate( divx(ib:ie,jb:je,kb:ke) )
      divx = 0.0
      allocate(  rho(ib:ie,jb:je,kb:ke) )
      rho = 0.0
      allocate(   rr(ib:ie,jb:je,kb:ke) )
      rr = 0.0
      allocate(   rf(ib:ie,jb:je,kb:ke) )
      rf = 0.0
      allocate(  prs(ib:ie,jb:je,kb:ke) )
      prs = 0.0
      allocate(  t11(ib:ie,jb:je,kb:ke) )
      t11 = 0.0
      allocate(  t12(ib:ie,jb:je,kb:ke) )
      t12 = 0.0
      allocate(  t13(ib:ie,jb:je,kb:ke) )
      t13 = 0.0
      allocate(  t22(ib:ie,jb:je,kb:ke) )
      t22 = 0.0
      allocate(  t23(ib:ie,jb:je,kb:ke) )
      t23 = 0.0
      allocate(  t33(ib:ie,jb:je,kb:ke) )
      t33 = 0.0

      allocate(   rru(ib:ie+1,jb:je,kb:ke) )
      rru = 0.0
      allocate(    us(ib:ie+1,jb:je,kb:ke) )
      us = 0.0
      allocate(    ua(ib:ie+1,jb:je,kb:ke) )
      ua = 0.0
      allocate(   u3d(ib:ie+1,jb:je,kb:ke) )
      u3d = 0.0
      allocate(  uten(ib:ie+1,jb:je,kb:ke) )
      uten = 0.0
      allocate( uten1(ib:ie+1,jb:je,kb:ke) )
      uten1 = 0.0

      allocate(   rrv(ib:ie,jb:je+1,kb:ke) )
      rrv = 0.0
      allocate(    vs(ib:ie,jb:je+1,kb:ke) )
      vs = 0.0
      allocate(    va(ib:ie,jb:je+1,kb:ke) )
      va = 0.0
      allocate(   v3d(ib:ie,jb:je+1,kb:ke) )
      v3d = 0.0
      allocate(  vten(ib:ie,jb:je+1,kb:ke) )
      vten = 0.0
      allocate( vten1(ib:ie,jb:je+1,kb:ke) )
      vten1 = 0.0

      allocate(   rrw(ib:ie,jb:je,kb:ke+1) )
      rrw = 0.0
      allocate(    ws(ib:ie,jb:je,kb:ke+1) )
      ws = 0.0
      allocate(    wa(ib:ie,jb:je,kb:ke+1) )
      wa = 0.0
      allocate(   w3d(ib:ie,jb:je,kb:ke+1) )
      w3d = 0.0
      allocate(  wten(ib:ie,jb:je,kb:ke+1) )
      wten = 0.0
      allocate( wten1(ib:ie,jb:je,kb:ke+1) )
      wten1 = 0.0

      allocate(   ppi(ib:ie,jb:je,kb:ke) )
      ppi = 0.0
      allocate(  pp3d(ib:ie,jb:je,kb:ke) )
      pp3d = 0.0
      allocate( piadv(ib:ie,jb:je,kb:ke) )
      piadv = 0.0
      allocate( ppten(ib:ie,jb:je,kb:ke) )
      ppten = 0.0
      allocate(  sten(ib:ie,jb:je,kb:ke) )
      sten = 0.0
      allocate(   ppx(ib:ie,jb:je,kb:ke) )
      ppx = 0.0

      allocate(   tha(ib:ie,jb:je,kb:ke) )
      tha = 0.0
      allocate(  th3d(ib:ie,jb:je,kb:ke) )
      th3d = 0.0
      allocate( thadv(ib:ie,jb:je,kb:ke) )
      thadv = 0.0
      allocate( thten(ib:ie,jb:je,kb:ke) )
      thten = 0.0
      allocate(thten1(ib:ie,jb:je,kb:ke) )
      thten1 = 0.0
      allocate(thterm(ib:ie,jb:je,kb:ke) )
      thterm = 0.0

      allocate( qpten(ibm:iem,jbm:jem,kbm:kem) )
      qpten = 0.0
      allocate( qtten(ibm:iem,jbm:jem,kbm:kem) )
      qtten = 0.0
      allocate( qvten(ibm:iem,jbm:jem,kbm:kem) )
      qvten = 0.0
      allocate( qcten(ibm:iem,jbm:jem,kbm:kem) )
      qcten = 0.0

      allocate(   bud(nk) )
      bud = 0.0
      allocate(  bud2(nj) )
      bud2 = 0.0
      allocate( qbudget(nbudget) )
      qbudget = 0.0
      allocate(    asq(numq) )
      asq = 0.0
      allocate(    bsq(numq) )
      bsq = 0.0

      allocate(     qa(ibm:iem,jbm:jem,kbm:kem,numq) )
      qa = 0.0
      allocate(    q3d(ibm:iem,jbm:jem,kbm:kem,numq) )
      q3d = 0.0
      allocate(   qten(ibm:iem,jbm:jem,kbm:kem,numq) )
      qten = 0.0

      allocate(    kmh(ibc:iec,jbc:jec,kbc:kec) )
      kmh = 0.0
      allocate(    kmv(ibc:iec,jbc:jec,kbc:kec) )
      kmv = 0.0
      allocate(    khh(ibc:iec,jbc:jec,kbc:kec) )
      khh = 0.0
      allocate(    khv(ibc:iec,jbc:jec,kbc:kec) )
      khv = 0.0
      allocate(   tkea(ibt:iet,jbt:jet,kbt:ket) )
      tkea = 0.0
      allocate(  tke3d(ibt:iet,jbt:jet,kbt:ket) )
      tke3d = 0.0
      allocate( tketen(ibt:iet,jbt:jet,kbt:ket) )
      tketen = 0.0

      allocate(      nm(ib:ie,jb:je,kb:ke+1) )
      nm = 0.0
      allocate(    defv(ib:ie,jb:je,kb:ke+1) )
      defv = 0.0
      allocate(    defh(ib:ie,jb:je,kb:ke+1) )
      defh = 0.0
      allocate( dissten(ib:ie,jb:je,kb:ke+1) )
      dissten = 0.0

      allocate( thpten(ibb:ieb,jbb:jeb,kbb:keb) )
      thpten = 0.0
      allocate( qvpten(ibb:ieb,jbb:jeb,kbb:keb) )
      qvpten = 0.0
      allocate( qcpten(ibb:ieb,jbb:jeb,kbb:keb) )
      qcpten = 0.0
      allocate( qipten(ibb:ieb,jbb:jeb,kbb:keb) )
      qipten = 0.0
      allocate(  upten(ibb:ieb,jbb:jeb,kbb:keb) )
      upten = 0.0
      allocate(  vpten(ibb:ieb,jbb:jeb,kbb:keb) )
      vpten = 0.0

      allocate( swten(ibr:ier,jbr:jer,kbr:ker) )
      swten = 0.0
      allocate( lwten(ibr:ier,jbr:jer,kbr:ker) )
      lwten = 0.0
      allocate(   o30(ibr:ier,jbr:jer,kbr:ker) )
      o30 = 0.0

      IF( radopt .eq. 1 )THEN
        nir = 1
        njr = 1
        nkr = nk+3
        rbufsz = n2d_radiat*nir*njr + n3d_radiat*nir*njr*nkr
      ELSE
        nir = 1
        njr = 1
        nkr = 1
        rbufsz = 1
      ENDIF

      allocate(    radsw(ni,nj) )
      radsw = 0.0
      allocate(    rnflx(ni,nj) )
      rnflx = 0.0
      allocate( radswnet(ni,nj) )
      radswnet = 0.0
      allocate(  radlwin(ni,nj) )
      radlwin = 0.0
      allocate(      dsr(ni,nj) )
      dsr = 0.0
      allocate(      olr(ni,nj) )
      olr = 0.0

      allocate(    rad2d(ni,nj,nrad2d) )
      rad2d = 0.0

      allocate(  effc(ibr:ier,jbr:jer,kbr:ker) )
      effc = 25.0
      allocate(  effi(ibr:ier,jbr:jer,kbr:ker) )
      effi = 25.0
      allocate(  effs(ibr:ier,jbr:jer,kbr:ker) )
      effs = 25.0
      allocate(  effr(ibr:ier,jbr:jer,kbr:ker) )
      effr = 25.0
      allocate(  effg(ibr:ier,jbr:jer,kbr:ker) )
      effg = 25.0
      allocate( effis(ibr:ier,jbr:jer,kbr:ker) )
      effis = 25.0

      if(dowr) write(outfile,*) '  rbufsz,nrad2d = ',rbufsz,nrad2d

      allocate( lu_index(ibl:iel,jbl:jel) )
      lu_index = 0
      allocate(   kpbl2d(ibl:iel,jbl:jel) )
      kpbl2d = 0
      allocate(      u10(ibl:iel,jbl:jel) )
      u10 = 0.0
      allocate(      v10(ibl:iel,jbl:jel) )
      v10 = 0.0
      allocate(      s10(ibl:iel,jbl:jel) )
      s10 = 0.0
      allocate(      hfx(ibl:iel,jbl:jel) )
      hfx = 0.0
      allocate(      qfx(ibl:iel,jbl:jel) )
      qfx = 0.0
      allocate(     hpbl(ibl:iel,jbl:jel) )
      hpbl = 0.0
      allocate(     wspd(ibl:iel,jbl:jel) )
      wspd = 0.0
      allocate(     psim(ibl:iel,jbl:jel) )
      psim = 0.0
      allocate(     psih(ibl:iel,jbl:jel) )
      psih = 0.0
      allocate(   gz1oz0(ibl:iel,jbl:jel) )
      gz1oz0 = 0.0
      allocate(       br(ibl:iel,jbl:jel) )
      br = 0.0
      allocate(      chs(ibl:iel,jbl:jel) )
      chs = 0.0
      allocate(     chs2(ibl:iel,jbl:jel) )
      chs2 = 0.0
      allocate(     cqs2(ibl:iel,jbl:jel) )
      cqs2 = 0.0
      allocate(     cpmm(ibl:iel,jbl:jel) )
      cpmm = 0.0
      allocate(      zol(ibl:iel,jbl:jel) )
      zol = 0.0
      allocate(   mavail(ibl:iel,jbl:jel) )
      mavail = 0.0
      allocate(      mol(ibl:iel,jbl:jel) )
      mol = 0.0
      allocate(     rmol(ibl:iel,jbl:jel) )
      rmol = 0.0
      allocate(   regime(ibl:iel,jbl:jel) )
      regime = 0.0
      allocate(       lh(ibl:iel,jbl:jel) )
      lh = 0.0
      allocate(     flhc(ibl:iel,jbl:jel) )
      flhc = 0.0
      allocate(     flqc(ibl:iel,jbl:jel) )
      flqc = 0.0
      allocate(      qgh(ibl:iel,jbl:jel) )
      qgh = 0.0
      allocate(       ck(ibl:iel,jbl:jel) )
      ck = 0.0
      allocate(      cka(ibl:iel,jbl:jel) )
      cka = 0.0
      allocate(      cda(ibl:iel,jbl:jel) )
      cda = 0.0
      allocate(     ustm(ibl:iel,jbl:jel) )
      ustm = 0.0
      allocate(     qsfc(ibl:iel,jbl:jel) )
      qsfc = 0.0
      allocate(       t2(ibl:iel,jbl:jel) )
      t2 = 0.0
      allocate(       q2(ibl:iel,jbl:jel) )
      q2 = 0.0
      allocate(      th2(ibl:iel,jbl:jel) )
      th2 = 0.0
      allocate(    emiss(ibl:iel,jbl:jel) )
      emiss = 0.0
      allocate(      thc(ibl:iel,jbl:jel) )
      thc = 0.0
      allocate(     albd(ibl:iel,jbl:jel) )
      albd = 0.0
      allocate(      f2d(ibl:iel,jbl:jel) )
      f2d = 0.0
      allocate(      gsw(ibl:iel,jbl:jel) )
      gsw = 0.0
      allocate(      glw(ibl:iel,jbl:jel) )
      glw = 0.0
      allocate(  chklowq(ibl:iel,jbl:jel) )
      chklowq = 0.0
      allocate(     capg(ibl:iel,jbl:jel) )
      capg = 0.0
      allocate(    snowc(ibl:iel,jbl:jel) )
      snowc = 0.0
      allocate(     dsxy(ibl:iel,jbl:jel) )
      dsxy = 0.0
      allocate(    wstar(ibl:iel,jbl:jel) )
      wstar = 0.0
      allocate(    delta(ibl:iel,jbl:jel) )
      delta = 0.0
      allocate(       fm(ibl:iel,jbl:jel) )
      fm = 0.0
      allocate(       fh(ibl:iel,jbl:jel) )
      fh = 0.0

      allocate(     mznt(ibl:iel,jbl:jel) )
      mznt = 0.0
      allocate(    smois(ibl:iel,jbl:jel) )
      smois = 0.0
      allocate(     taux(ibl:iel,jbl:jel) )
      taux = 0.0
      allocate(     tauy(ibl:iel,jbl:jel) )
      tauy = 0.0
      allocate(   hpbl2d(ibl:iel,jbl:jel) )
      hpbl2d = 0.0
      allocate(   evap2d(ibl:iel,jbl:jel) )
      evap2d = 0.0
      allocate(   heat2d(ibl:iel,jbl:jel) )
      heat2d = 0.0
      allocate(     rc2d(ibl:iel,jbl:jel) )
      rc2d = 0.0

      ! start with very small, but non-zero, numbers:
      znt = 1.0e-6
      ust = 1.0e-6
      ! to prevent divide-by-zeros for some combinations of namelist params:
      tsk  = 300.0
      psfc = 100000.0
      qsfc = 0.00001

      num_soil_layers = 5
      allocate(  slab_zs(num_soil_layers) )
      slab_zs = 0.0
      allocate( slab_dzs(num_soil_layers) )
      slab_dzs = 0.0
      allocate(  tslb(ibl:iel,jbl:jel,num_soil_layers) )
      tslb = 0.0
      allocate(   tmn(ibl:iel,jbl:jel) )
      tmn = 0.0

      ! arrays for oml model:
      allocate(   tml(ibl:iel,jbl:jel) )
      tml = 0.0
      allocate(  t0ml(ibl:iel,jbl:jel) )
      t0ml = 0.0
      allocate(   hml(ibl:iel,jbl:jel) )
      hml = 0.0
      allocate(  h0ml(ibl:iel,jbl:jel) )
      h0ml = 0.0
      allocate(  huml(ibl:iel,jbl:jel) )
      huml = 0.0
      allocate(  hvml(ibl:iel,jbl:jel) )
      hvml = 0.0
      allocate( tmoml(ibl:iel,jbl:jel) )
      tmoml = 0.0

      allocate(    pta(ibp:iep,jbp:jep,kbp:kep,npt) )
      pta = 0.0
      allocate(   pt3d(ibp:iep,jbp:jep,kbp:kep,npt) )
      pt3d = 0.0
      allocate(  ptten(ibp:iep,jbp:jep,kbp:kep,npt) )
      ptten = 0.0

      allocate( dat1(ni+1,nj+1) )
      dat1 = 0.0
      allocate( dat2(d2i,d2j) )
      dat2 = 0.0
      allocate( dat3(d3i,d3j,d3n) )
      dat3 = 0.0
      allocate( reqt(d3t) )
      reqt = 0


      allocate(  pdata(npvals,nparcels) )
      pdata = 0.0
      allocate( packet(npvals,nparcels) )
      packet = 0.0
      allocate(   ploc(  3   ,nparcels) )
      ploc = 0.0

      allocate( flag(ib:ie,jb:je,kb:ke) )
      flag = .false.

      allocate(    cfb(ipb:ipe,jpb:jpe,kpb:kpe) )
      cfb = 0.0
      allocate(    cfa(kpb:kpe) )
      cfa = 0.0
      allocate(    cfc(kpb:kpe) )
      cfc = 0.0
      allocate(     d1(kpb:kpe) )
      d1 = 0.0
      allocate(     d2(kpb:kpe) )
      d2 = 0.0
      allocate(    pdt(ipb:ipe,jpb:jpe,kpb:kpe) )
      pdt = 0.0
      allocate(   deft(ipb:ipe,jpb:jpe,kpb:kpe) )
      deft = 0.0
      allocate(    rhs(ipb:ipe,jpb:jpe) )
      rhs = 0.0
      allocate(  trans(ipb:ipe,jpb:jpe) )
      trans = 0.0

      call init3d(xh,rxh,uh,ruh,xf,rxf,uf,ruf,yh,vh,rvh,yf,vf,rvf,  &
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
                  pdata,cfb,cfa,cfc,d1,d2,pdt,deft,rhs,trans)


!----------------------------------------------------------------------

      if(ibalance.eq.2 .and.  psolver.ne.4.and.psolver.ne.5 )then
        deallocate( cfb )
        deallocate( cfa )
        deallocate( cfc )
        deallocate( d1 )
        deallocate( d2 )
        deallocate( pdt )
        deallocate( deft )
        deallocate( rhs )
        deallocate( trans )
        ipb = 1
        ipe = 1
        jpb = 1
        jpe = 1
        kpb = 1
        kpe = 1
        allocate(    cfb(ipb:ipe,jpb:jpe,kpb:kpe) )
        cfb = 0.0
        allocate(    cfa(kpb:kpe) )
        cfa = 0.0
        allocate(    cfc(kpb:kpe) )
        cfc = 0.0
        allocate(     d1(kpb:kpe) )
        d1 = 0.0
        allocate(     d2(kpb:kpe) )
        d2 = 0.0
        allocate(    pdt(ipb:ipe,jpb:jpe,kpb:kpe) )
        pdt = 0.0
        allocate(   deft(ipb:ipe,jpb:jpe,kpb:kpe) )
        deft = 0.0
        allocate(    rhs(ipb:ipe,jpb:jpe) )
        rhs = 0.0
        allocate(  trans(ipb:ipe,jpb:jpe) )
        trans = 0.0
      endif

      if( myid.eq.0 ) print *
      if( myid.eq.0 ) print *,'  allocating diagnostic arrays:  ntdiag,nqdiag = ',ntdiag,nqdiag
      if( myid.eq.0 ) print *

      allocate( tdiag(ibd:ied,jbd:jed,kbd:ked,ntdiag) )
      tdiag = 0.0
      allocate( qdiag(ibd:ied,jbd:jed,kbd:ked,nqdiag) )
      qdiag = 0.0

!----------------------------------------------------------------------

      call setup_output(tdef,qname,budname,xh,xf,yh,yf,xfref,yfref,sigma,sigmaf,zh,zf)

      call init_physics(prs0,rf0,dum1,dum2,dum3,u0,ua,v0,va,o30,   &
                             lu_index,xland,emiss,thc,albd,znt,mavail,f2d,tsk,u1,v1,s1, &
                             zh,u10,v10,wspd)

      call init_surface(num_soil_layers,dosfcflx,xh,ruh,xf,yh,rvh,yf,   &
                        lu_index,xland,tsk,slab_zs,slab_dzs,tslb, &
                        emiss,thc,albd,znt,mavail,dsxy,prs0s,prs0,   &
                        tmn,tml,t0ml,hml,h0ml,huml,hvml,tmoml)

      if(irst.eq.1)then
        restart = .true.
        call     read_restart(nstep,nrec,prec,nwrite,nrst,num_soil_layers,         &
                              dt,dtlast,mtime,ndt,adt,acfl,dbldt,mass1,            &
                              stattim,taptim,rsttim,radtim,prcltim,                &
                              qbudget,asq,bsq,qname,                               &
                              xfref,yfref,zh,zf,sigma,sigmaf,zs,                   &
                              th0,prs0,pi0,rho0,qv0,u0,v0,                         &
                              rain,sws,svs,sps,srs,sgs,sus,shs,                    &
                              tsk,znt,ust,cd,ch,cq,u1,v1,s1,thflux,qvflux,         &
                              radbcw,radbce,radbcs,radbcn,                         &
                              rho,prs,ua,va,wa,ppi,tha,qa,tkea,                    &
                              swten,lwten,radsw,rnflx,radswnet,radlwin,rad2d,      &
                              effc,effi,effs,effr,effg,effis,                      &
                              lu_index,kpbl2d,psfc,u10,v10,s10,hfx,qfx,xland,      &
                              hpbl,wspd,psim,psih,gz1oz0,br,                       &
                              CHS,CHS2,CQS2,CPMM,ZOL,MAVAIL,                       &
                              MOL,RMOL,REGIME,LH,FLHC,FLQC,QGH,                    &
                              CK,CKA,CDA,USTM,QSFC,T2,Q2,TH2,EMISS,THC,ALBD,       &
                              f2d,gsw,glw,chklowq,capg,snowc,fm,fh,tslb,           &
                              tmn,tml,t0ml,hml,h0ml,huml,hvml,tmoml,               &
                              qpten,qtten,qvten,qcten,pta,pdata,ploc,ppx,sten,     &
                              ntdiag,nqdiag,tdiag,qdiag,                           &
                              dum1,dat1,dat2,dat3,reqt,restart_prcl)
        !  In case user wants to change values on a restart:
        IF( restart_reset_frqtim )THEN 
          if( statfrq.gt.0.0 ) stattim = mtime + statfrq
          if(  tapfrq.gt.0.0 ) taptim  = mtime + tapfrq
          if(  rstfrq.gt.0.0 ) rsttim  = mtime + rstfrq
        ENDIF
        if(dowr) write(outfile,*)
        if(dowr) write(outfile,*) '  Using the following: '
        if(dowr) write(outfile,*)
        if(dowr) write(outfile,*) '   stattim = ',stattim
        if(dowr) write(outfile,*) '   taptim  = ',taptim
        if(dowr) write(outfile,*) '   rsttim  = ',rsttim
        if(dowr) write(outfile,*) '   radtim  = ',radtim
        if(dowr) write(outfile,*)
      else
        restart = .false.
        restart_prcl = .false.
      endif

      IF( run_time .gt. 0.0 )THEN
        timax = mtime + run_time
        if(dowr) write(outfile,*)
        if(dowr) write(outfile,*) '  Detected positive value for run_time. '
        if(dowr) write(outfile,*) '     Using the following values: '
        if(dowr) write(outfile,*) '        run_time = ',run_time
        if(dowr) write(outfile,*) '        timax    = ',timax
        if(dowr) write(outfile,*)
        call setup_output(tdef,qname,budname,xh,xf,yh,yf,xfref,yfref,sigma,sigmaf,zh,zf)
      ENDIF

      call       getset(restart,mass1,ruh,rvh,xf,                          &
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

      rtime=sngl(mtime)

!cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!cc   Prepare turbulence vars for first time step  cccccccccccccccccc
!cc     (new since cm1r17)                         cccccccccccccccccc
!cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

        getsfc = .true.
        if( restart ) getsfc = .false.
        call sfc_and_turb(getsfc,nstep,dt,dosfcflx,cloudvar,qbudget, &
                   xh,rxh,arh1,arh2,uh,ruh,xf,rxf,arf1,arf2,uf,ruf,  &
                   yh,vh,rvh,yf,vf,rvf,                              &
                   rds,sigma,rdsf,sigmaf,zh,mh,rmh,c1,c2,zf,mf,rmf,  &
                   pi0s,rth0s,pi0,rho0,prs0,thv0,th0,qv0,            &
                   zs,gz,rgz,gzu,rgzu,gzv,rgzv,gx,gxu,gy,gyv,        &
                   tsk,thflux,qvflux,cd,ch,cq,u1,v1,s1,tlh,          &
                   dum1,dum2,dum3,dum4,dum5,dum6,dum7,dum8,          &
                   divx,rho,rr,rf,prs,                               &
                   t11,t12,t13,t22,t23,t33,                          &
                   u0,ua,v0,va,wa,                                   &
                   ppi,pp3d,ppten,                                   &
                   tha,th3d,thten,thten1,qa,                         &
                   kmh,kmv,khh,khv,tkea,tke3d,                       &
                   nm,defv,defh,dissten,radsw,radswnet,radlwin,      &
                   thpten,qvpten,qcpten,qipten,upten,vpten,          &
                   lu_index,kpbl2d,psfc,u10,v10,s10,hfx,qfx,xland,znt,ust,    &
                   hpbl,wspd,psim,psih,gz1oz0,br,                    &
                   CHS,CHS2,CQS2,CPMM,ZOL,MAVAIL,                    &
                   MOL,RMOL,REGIME,LH,FLHC,FLQC,QGH,                 &
                   CK,CKA,CDA,USTM,QSFC,T2,Q2,TH2,EMISS,THC,ALBD,    &
                   f2d,gsw,glw,chklowq,capg,snowc,dsxy,wstar,delta,fm,fh,  &
                   mznt,smois,taux,tauy,hpbl2d,evap2d,heat2d,rc2d,   &
                   num_soil_layers,slab_zs,slab_dzs,tslb,tmn,        &
                   tml,t0ml,hml,h0ml,huml,hvml,tmoml,                &
                   reqs_u,reqs_v,reqs_w,reqs_s,reqs_p,               &
                   nw1,nw2,ne1,ne2,sw1,sw2,se1,se2,                  &
                   pw1,pw2,pe1,pe2,ps1,ps2,pn1,pn2,                  &
                   vw1,vw2,ve1,ve2,vs1,vs2,vn1,vn2,                  &
                   uw31,uw32,ue31,ue32,us31,us32,un31,un32,          &
                   kw1,kw2,ke1,ke2,ks1,ks2,kn1,kn2,                  &
                   rtime,ntdiag,tdiag,.false.)
        ! end_sfc_and_turb

!--------------------------------------------------------------------
!  get stress terms for explicit diffusion scheme:

      IF( ((idiff.ge.1).and.(difforder.eq.2)) .or. (dns.eq.1) )THEN
        call diff2def(uh,arh1,arh2,uf,arf1,arf2,vh,vf,mh,c1,c2,mf,ust,znt,u1,v1,s1,  &
                      divx,rho,rr,rf,t11,t12,t13,t22,t23,t33,ua,va,wa,dissten)
      ENDIF

!----------------------------------------------------------------------
!  All done with initialization.  A few more odds and ends ....

      if( adapt_dt.eq.1 )then
        dt = dbldt
        call dtsmall(dt)
        if( .not. restart )then
          call calccflquick(dt,uh,vh,mh,u3d,v3d,w3d)
          ndt = 1
          adt = dt
          acfl = cflmax
        endif
        IF( (imoist.eq.1).and.(ptype.eq.2) )then
          call consat2(dt)
        ENDIF
        IF( (imoist.eq.1).and.(ptype.eq.4) )then
          call lfoice_init(dt)
        ENDIF
      endif

      if( .not. restart )then
        if(dowr) write(outfile,*)
        if(dowr) write(outfile,*) '  initial conditions:'
        if(dowr) write(outfile,*)
      endif

      IF(axisymm.eq.0)THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk
        do j=1,nj
        do i=1,ni
          ppten(i,j,k)=rho(i,j,k)
        enddo
        enddo
        enddo
      ELSE
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk
        do j=1,nj
        do i=1,ni
          ppten(i,j,k) = rho(i,j,k)*pi*(xf(i+1)**2-xf(i)**2)/(dx*dy)
        enddo
        enddo
        enddo
      ENDIF
      reset = .false.
      call       statpack(nrec,ndt,dt,dtlast,rtime,adt,acfl,cloudvar,qname,budname,qbudget,asq,bsq, &
                          xh,rxh,uh,ruh,xf,uf,yh,vh,rvh,vf,zh,mh,rmh,mf,    &
                          zs,rgzu,rgzv,rds,sigma,rdsf,sigmaf,               &
                          rstat,pi0,rho0,thv0,th0,qv0,u0,v0,                &
                          dum1,dum2,dum3,dum4,dum5,ppten,prs,               &
                          ua,va,wa,ppi,tha,qa,qten,kmh,kmv,khh,khv,tkea,pta,u10,v10,reset)
      IF( adapt_dt.eq.1 )THEN
        ndt  = 0
        adt  = 0.0
        acfl = 0.0
      ENDIF

!-------------------------------------------------------------------
    IF( .not. restart )THEN
      ! Initial conditions:  (do not write if this is a restart)
      IF(output_format.eq.1.or.output_format.eq.2)THEN
        sten = 0.0
        nn = 1
        if(terrain_flag .and. output_interp.eq.1) nn = 2
        if(output_format.eq.2) nn = 1
        DO n=1,nn
          if(n.eq.1)then
            fnum = 51
          else
            fnum = 71
          endif
          call writeout(rtime,dt,fnum,nwrite,qname,xh,xf,uf,yh,yf,vf,xfref,yfref,              &
                        rds,sigma,rdsf,sigmaf,zh,zf,mf,gx,gy,                                  &
                        pi0,prs0,rho0,rr0,rf0,rrf0,th0,qv0,u0,v0,                              &
                        zs,rgzu,rgzv,rain,sws,svs,sps,srs,sgs,sus,shs,thflux,qvflux,psfc,      &
                        rxh,arh1,arh2,uh,ruh,rxf,arf1,arf2,vh,rvh,mh,rmf,rr,rf,                &
                        gz,rgz,gzu,gzv,gxu,gyv,dzdx,dzdy,c1,c2,                                &
                        cd,ch,cq,tlh,dum1,dum2,dum3,dum4,dum5,dum6,dum7,dum8,                  &
                        t11,t12,t13,t22,t23,t33,rho,prs,sten,                                  &
                        rru,ua,u3d,uten,rrv,va,v3d,vten,rrw,wa,w3d,wten,ppi,tha,               &
                        us,vs,ws,thadv,thten,nm,defv,defh,dissten,                             &
                        thpten,qvpten,qcpten,qipten,upten,vpten,                               &
                        lu_index,xland,mavail,tsk,tmn,tml,hml,huml,hvml,hfx,qfx,gsw,glw,tslb,  &
                        qa,kmh,kmv,khh,khv,tkea,swten,lwten,                                   &
                        radsw,rnflx,radswnet,radlwin,dsr,olr,pta,                              &
                        num_soil_layers,u10,v10,t2,q2,znt,ust,u1,v1,s1,                        &
                        hpbl,zol,mol,br,psim,psih,qsfc,                                        &
                        dat1,dat2,dat3,reqt,ntdiag,nqdiag,tdiag,qdiag,                         &
                        nw1,nw2,ne1,ne2,sw1,sw2,se1,se2)
        ENDDO
      ENDIF
    ENDIF  ! endif for .not. restart
!-------------------------------------------------------------------

!-------------------------------------------------------------------
!  Write parcel data:
      IF( iprcl.eq.1 )THEN
      if( .not. restart_prcl )then
        call     parcel_interp(dt,xh,uh,ruh,xf,uf,yh,vh,rvh,yf,vf,     &
                               zh,mh,rmh,zf,mf,znt,ust,c1,c2,          &
                               pi0,th0,thv0,qv0,qc0,qi0,rth0,          &
                               dum1,dum2,dum3,dum4,dum5,dum6,prs,rho,  &
                               sten,dum7,dum8,wten,wten1,              &
                               u3d,v3d,w3d,pp3d,thten,thten1,th3d,q3d, &
                               kmh,kmv,khh,khv,tke3d,pt3d,pdata,       &
                               packet,reqs_p,                          &
                               pw1,pw2,pe1,pe2,ps1,ps2,pn1,pn2,        &
                               nw1,nw2,ne1,ne2,sw1,sw2,se1,se2)
        rtime = sngl(mtime)
        call parcel_write(prec,rtime,qname,pdata,ploc)
      
      else
        if(myid.eq.0) print *
        if(myid.eq.0) print *,'  NOTE:  skipping parcel_write '
        if(myid.eq.0) print *
      endif
        ! next parcel write time will be "prclfrq" seconds in the future:
        prcltim = mtime + prclfrq
        if(myid.eq.0) print *
        if(myid.eq.0) print *,'  prcltim = ',prcltim
        if(myid.eq.0) print *
      ENDIF

!-------------------------------------------------------------------

      rtime=sngl(mtime)
      if(myid.eq.0)then
        if(timeformat.eq.1)then
          write(6,110) nstep,rtime,' sec '
        elseif(timeformat.eq.2)then
          write(6,110) nstep,rtime/60.0,' min '
        elseif(timeformat.eq.3)then
          write(6,110) nstep,rtime/3600.0,' hour'
        elseif(timeformat.eq.4)then
          write(6,110) nstep,rtime/86400.0,' day '
        else
          write(6,110) nstep,rtime,' sec'
        endif
110     format(2x,i12,4x,f18.6,a5)
      endif

      if(dowr) write(outfile,*)
      if(dowr) write(outfile,*) '-------------Done with Preprocessors-----------'
      if(dowr) write(outfile,*)

      if(iconly.eq.1)then
        if(dowr) write(outfile,*)
        if(dowr) write(outfile,*) '  User has requested initial conditions only'
        if(dowr) write(outfile,*) '     (iconly = 1)'
        if(dowr) write(outfile,*) '  ... stopping ... '
        if(dowr) write(outfile,*)
        stop 55555
      endif

!----------------------------------------------------------------------
!  150820:  Write restart file if rstfrq=0 and stop

      IF( abs(rstfrq).lt.0.0001 )THEN
        nrst = 0
        if(dowr) write(outfile,*)
        if(dowr) write(outfile,*) '  Detected rstfrq = 0 '
        if(dowr) write(outfile,*) '  ... writing restart file ... '
        if(dowr) write(outfile,*)
        call     write_restart(nstep,nrec,prec,nwrite,nrst,num_soil_layers,         &
                               dt,dtlast,mtime,ndt,adt,acfl,dbldt,mass1,            &
                               stattim,taptim,rsttim,radtim,prcltim,                &
                               qbudget,asq,bsq,qname,                               &
                               xfref,yfref,zh,zf,sigma,sigmaf,zs,                   &
                               th0,prs0,pi0,rho0,qv0,u0,v0,                         &
                               rain,sws,svs,sps,srs,sgs,sus,shs,                    &
                               tsk,znt,ust,cd,ch,cq,u1,v1,s1,thflux,qvflux,         &
                               radbcw,radbce,radbcs,radbcn,                         &
                               rho,prs,ua,va,wa,ppi,tha,qa,tkea,                    &
                               swten,lwten,radsw,rnflx,radswnet,radlwin,rad2d,      &
                               effc,effi,effs,effr,effg,effis,                      &
                               lu_index,kpbl2d,psfc,u10,v10,s10,hfx,qfx,xland,      &
                               hpbl,wspd,psim,psih,gz1oz0,br,                       &
                               CHS,CHS2,CQS2,CPMM,ZOL,MAVAIL,                       &
                               MOL,RMOL,REGIME,LH,FLHC,FLQC,QGH,                    &
                               CK,CKA,CDA,USTM,QSFC,T2,Q2,TH2,EMISS,THC,ALBD,       &
                               f2d,gsw,glw,chklowq,capg,snowc,fm,fh,tslb,           &
                               tmn,tml,t0ml,hml,h0ml,huml,hvml,tmoml,               &
                               qpten,qtten,qvten,qcten,pta,pdata,ploc,ppx,sten,     &
                               ntdiag,nqdiag,tdiag,qdiag,                           &
                               dum1,dat1,dat2,dat3,reqt)
        if(dowr) write(outfile,*)
        if(dowr) write(outfile,*) '  ... stopping ... '
        if(dowr) write(outfile,*)
        stop 55556
      ENDIF

!----------------------------------------------------------------------

      time_sound=0.
      time_poiss=0.
      time_advs=0.
      time_advu=0.
      time_advv=0.
      time_advw=0.
      time_buoyan=0.
      time_turb=0.
      time_diffu=0.
      time_microphy=0.
      time_stat=0.
      time_cflq=0.
      time_bc=0.
      time_misc=0.
      time_integ=0.
      time_rdamp=0.
      time_divx=0.
      time_write=0.
      time_restart=0.
      time_tmix=0.
      time_cor=0.
      time_fall=0.
      time_satadj=0.
      time_sfcphys=0.
      time_parcels=0.0
      time_rad=0.
      time_pbl=0.
      time_swath=0.
      time_pdef=0.
      time_prsrho=0.

      ! This initializes timer
      if(timestats.ge.1)then
        call system_clock(count,rate,maxr)
        clock_rate=1.0/rate
        xtime=mytime()
      endif

!----------------------------------------------------------------------
!  Time loop

      if(timestats.ge.1)then
        steptime1 = 0.0
        steptime2 = 0.0
      endif

      nstep0 = nstep

      do while( mtime.lt.timax )
        nstep = nstep + 1
        call     solve(nstep,nrec,prec,nwrite,nrst,rbufsz,num_soil_layers,ndt,ntdiag,nqdiag, &
                   dt,dtlast,mtime,stattim,taptim,rsttim,radtim,prcltim,adt,acfl,dbldt,mass1,mass2, &
                   dosfcflx,cloudvar,rhovar,qname,budname,bud,bud2,qbudget,asq,bsq, &
                   xh,rxh,arh1,arh2,uh,ruh,xf,rxf,arf1,arf2,uf,ruf,yh,vh,rvh,yf,vf,rvf,   &
                   xfref,yfref,dumk1,dumk2,rds,sigma,rdsf,sigmaf,     &
                   tauh,taus,zh,mh,rmh,c1,c2,tauf,zf,mf,rmf,          &
                   rstat,rho0s,pi0s,prs0s,rth0s,pi0,rho0,prs0,thv0,th0,rth0,qv0,qc0,  &
                   qi0,rr0,rf0,rrf0,                                  &
                   zs,gz,rgz,gzu,rgzu,gzv,rgzv,dzdx,dzdy,gx,gxu,gy,gyv, &
                   rain,sws,svs,sps,srs,sgs,sus,shs,                  &
                   tsk,thflux,qvflux,cd,ch,cq,u1,v1,s1,tlh,           &
                   radbcw,radbce,radbcs,radbcn,                       &
                   dum1,dum2,dum3,dum4,dum5,dum6,dum7,dum8,           &
                   divx,rho,rr,rf,prs,                                &
                   t11,t12,t13,t22,t23,t33,                           &
                   u0,rru,us,ua,u3d,uten,uten1,                       &
                   v0,rrv,vs,va,v3d,vten,vten1,                       &
                   rrw,ws,wa,w3d,wten,wten1,                          &
                   ppi,pp3d,piadv,ppten,sten,ppx,                     &
                   tha,th3d,thadv,thten,thten1,thterm,                &
                   qpten,qtten,qvten,qcten,qa,q3d,qten,               &
                   kmh,kmv,khh,khv,tkea,tke3d,tketen,                 &
                   nm,defv,defh,dissten,                              &
                   thpten,qvpten,qcpten,qipten,upten,vpten,           &
                   swten,lwten,o30,radsw,rnflx,radswnet,radlwin,dsr,olr,rad2d, &
                   effc,effi,effs,effr,effg,effis,                    &
                   lu_index,kpbl2d,psfc,u10,v10,s10,hfx,qfx,xland,znt,ust,   &
                   hpbl,wspd,psim,psih,gz1oz0,br,                     &
                   CHS,CHS2,CQS2,CPMM,ZOL,MAVAIL,                     &
                   MOL,RMOL,REGIME,LH,FLHC,FLQC,QGH,                  &
                   CK,CKA,CDA,USTM,QSFC,T2,Q2,TH2,EMISS,THC,ALBD,     &
                   f2d,gsw,glw,chklowq,capg,snowc,dsxy,wstar,delta,fm,fh,   &
                   mznt,smois,taux,tauy,hpbl2d,evap2d,heat2d,rc2d,    &
                   slab_zs,slab_dzs,tslb,tmn,tml,t0ml,hml,h0ml,huml,hvml,tmoml,        &
                   pta,pt3d,ptten,pdata,packet,ploc,                  &
                   cfb,cfa,cfc, d1, d2,pdt,deft,rhs,trans,flag,       &
                   reqs_u,reqs_v,reqs_w,reqs_s,reqs_p,reqs_tk,reqs_q,reqs_t, &
                   nw1,nw2,ne1,ne2,sw1,sw2,se1,se2,                  &
                   n3w1,n3w2,n3e1,n3e2,s3w1,s3w2,s3e1,s3e2,          &
                   ww1,ww2,we1,we2,ws1,ws2,wn1,wn2,                  &
                   pw1,pw2,pe1,pe2,ps1,ps2,pn1,pn2,                  &
                   vw1,vw2,ve1,ve2,vs1,vs2,vn1,vn2,                  &
                   uw31,uw32,ue31,ue32,us31,us32,un31,un32,          &
                   vw31,vw32,ve31,ve32,vs31,vs32,vn31,vn32,          &
                   ww31,ww32,we31,we32,ws31,ws32,wn31,wn32,          &
                   sw31,sw32,se31,se32,ss31,ss32,sn31,sn32,          &
                   rw31,rw32,re31,re32,rs31,rs32,rn31,rn32,          &
                   qw31,qw32,qe31,qe32,qs31,qs32,qn31,qn32,          &
                   tkw1,tkw2,tke1,tke2,tks1,tks2,tkn1,tkn2,          &
                   kw1,kw2,ke1,ke2,ks1,ks2,kn1,kn2,                  &
                   tw1,tw2,te1,te2,ts1,ts2,tn1,tn2,                  &
                   dat1,dat2,dat3,reqt,tdiag,qdiag)
        ! end_solve
        if(timestats.eq.2)then
          steptime2=time_sound+time_poiss+time_buoyan+time_turb+            &
                    time_diffu+time_microphy+time_stat+time_cflq+           &
                    time_bc+time_misc+time_integ+time_rdamp+time_divx+      &
                    time_write+time_restart+time_tmix+time_cor+time_fall+   &
                    time_satadj+time_sfcphys+time_parcels+                  &
                    time_rad+time_pbl+time_swath+time_pdef+time_prsrho+     &
                    time_advs+time_advu+time_advv+time_advw
          write(6,157) nstep,steptime2-steptime1
157       format('    timing for time step ',i12,':',f12.4,' s')
          steptime1 = steptime2
        endif
      enddo

!----------------------------------------------------------------------
!  write new stats descriptor file, if necessary:

      IF( output_format.eq.1 .and. myid.eq.0 )THEN
        IF( adapt_dt.eq.1 .and. statfrq.lt.0.0 )THEN
          print *,'  re-writing GrADS stats descriptor file .... '
          call write_statsctl(tdef,qname,budname,nstep+1)
        ENDIF
      ENDIF

!----------------------------------------------------------------------

!----------------------------------------------------------------------

    IF(timestats.ge.1)THEN


      time_solve=time_sound+time_poiss+time_buoyan+time_turb+             &
                  time_diffu+time_microphy+time_stat+time_cflq+           &
                  time_bc+time_misc+time_integ+time_rdamp+time_divx+      &
                  time_write+time_restart+time_tmix+time_cor+time_fall+   &
                  time_satadj+time_sfcphys+time_parcels+                  &
                  time_rad+time_pbl+time_swath+time_pdef+time_prsrho+     &
                  time_advs+time_advu+time_advv+time_advw
      time_solve0 = time_solve


      if(dowr) write(outfile,*)
      if(dowr) write(outfile,*) 'Total time: ',time_solve
      if(dowr) write(outfile,*)
      time_solve=0.01*time_solve
      if(time_solve.lt.0.0001) time_solve=1.

    IF(dowr)THEN
      write(outfile,100) 'sound   ',time_sound,time_sound/time_solve
      write(outfile,100) 'poiss   ',time_poiss,time_poiss/time_solve
      write(outfile,100) 'advs    ',time_advs,time_advs/time_solve
      write(outfile,100) 'advu    ',time_advu,time_advu/time_solve
      write(outfile,100) 'advv    ',time_advv,time_advv/time_solve
      write(outfile,100) 'advw    ',time_advw,time_advw/time_solve
      write(outfile,100) 'divx    ',time_divx,time_divx/time_solve
      write(outfile,100) 'buoyan  ',time_buoyan,time_buoyan/time_solve
      write(outfile,100) 'turb    ',time_turb,time_turb/time_solve
      write(outfile,100) 'sfcphys ',time_sfcphys,time_sfcphys/time_solve
      write(outfile,100) 'tmix    ',time_tmix,time_tmix/time_solve
      write(outfile,100) 'cor     ',time_cor,time_cor/time_solve
      write(outfile,100) 'diffu   ',time_diffu,time_diffu/time_solve
      write(outfile,100) 'rdamp   ',time_rdamp,time_rdamp/time_solve
      write(outfile,100) 'microphy',time_microphy,time_microphy/time_solve
      write(outfile,100) 'satadj  ',time_satadj,time_satadj/time_solve
      write(outfile,100) 'fallout ',time_fall,time_fall/time_solve
      write(outfile,100) 'radiatio',time_rad,time_rad/time_solve
      write(outfile,100) 'pbl     ',time_pbl,time_pbl/time_solve
      write(outfile,100) 'stat    ',time_stat,time_stat/time_solve
      write(outfile,100) 'cflq    ',time_cflq,time_cflq/time_solve
      write(outfile,100) 'bc      ',time_bc,time_bc/time_solve
      write(outfile,100) 'integ   ',time_integ,time_integ/time_solve
      write(outfile,100) 'write   ',time_write,time_write/time_solve
      write(outfile,100) 'restart ',time_restart,time_restart/time_solve
      write(outfile,100) 'misc    ',time_misc,time_misc/time_solve
      write(outfile,100) 'swaths  ',time_swath,time_swath/time_solve
      write(outfile,100) 'pdef    ',time_pdef,time_pdef/time_solve
      write(outfile,100) 'prsrho  ',time_prsrho,time_prsrho/time_solve
      write(outfile,100) 'parcels ',time_parcels,time_parcels/time_solve
      write(outfile,*)
    ENDIF

100   format(3x,a8,' :  ',f10.2,2x,f6.2,'%')


    ENDIF

!  End time loop
!----------------------------------------------------------------------

      close(unit=51)
      close(unit=52)
      close(unit=53)
      close(unit=54)
      close(unit=60)

!----------------------------------------------------------------------

      print *,'Program terminated normally'

      stop

8888  print *
      print *,'  8888: error opening or reading namelist.input '
      print *,'    ... stopping cm1 ... '
      call stopcm1

      end program cm1


