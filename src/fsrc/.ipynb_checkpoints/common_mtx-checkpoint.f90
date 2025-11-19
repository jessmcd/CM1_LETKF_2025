MODULE common_mtx
!=======================================================================
!
! [PURPOSE:] Matrix Functions
!
! [CREATED:] 07/20/2004 Takemasa Miyoshi
! [UPDATED:] 10/16/2004 Takemasa Miyoshi
!
! [PUBLIC:]
!   mtx_eigen  : eigenvalue decomposition
!   mtx_inv    : real symmetric matrix inverse
!   mtx_sqrt   : real symmetric matrix square root
!
! [REFERENCES:]
!    Core subroutines are adapted from netlib.org
!
! [HISTORY:]
!  07/20/2003 Takemasa Miyoshi  Created at University of Maryland, College Park
!
!=======================================================================

  IMPLICIT NONE

  PRIVATE
  PUBLIC :: mtx_eigen, mtx_inv, mtx_sqrt, mtx_inv_rg
  
!-----------------------------------------------------------------------
! Variable size definitions
!-----------------------------------------------------------------------
  INTEGER,PARAMETER :: r_size=kind(0.0d0)
  INTEGER,PARAMETER :: r_dble=kind(0.0d0)
  INTEGER,PARAMETER :: r_sngl=kind(0.0e0)
!-----------------------------------------------------------------------
! Constants
!-----------------------------------------------------------------------
  REAL(r_size),PARAMETER :: pi=3.1415926535
  REAL(r_size),PARAMETER :: gg=9.81
  REAL(r_size),PARAMETER :: rd=287.0
  REAL(r_size),PARAMETER :: cp=1005.7
  REAL(r_size),PARAMETER :: re=6371.3e3
  REAL(r_size),PARAMETER :: r_omega=7.292e-5
  REAL(r_size),PARAMETER :: t0c=273.15
  REAL(r_size),PARAMETER :: undef=-9.99e33


CONTAINS
!=======================================================================
!  Eigenvalue decomposition using subroutine rs
!    INPUT
!      INTEGER :: imode           : mode switch (0: only eiven values)
!      INTEGER :: n               : dimension of matrix
!      REAL(r_size) :: a(n,n)     : input matrix
!    OUTPUT
!      REAL(r_size) :: eival(n)   : eiven values in decending order
!                                   i.e. eival(1) is the largest
!      REAL(r_size) :: eivec(n,n) : eiven vectors
!      INTEGER :: nrank_eff       : number of positive eivenvalues
!=======================================================================
SUBROUTINE mtx_eigen(imode,n,a,eival,eivec,nrank_eff,error_flag)
  IMPLICIT NONE

  INTEGER,INTENT(IN) :: imode ! 0: calculate only eigen values
  INTEGER,INTENT(IN) :: n
  INTEGER,INTENT(INOUT) :: error_flag
  REAL(r_size),INTENT(IN) :: a(1:n,1:n)
  REAL(r_size),INTENT(OUT) :: eival(1:n)
  REAL(r_size),INTENT(OUT) :: eivec(1:n,1:n)
  INTEGER,INTENT(OUT) :: nrank_eff

  REAL(r_dble) :: a8(n,n)
  REAL(r_dble) :: eival8(n)
  REAL(r_dble) :: eivec8(n,n)
  REAL(r_dble) :: wrk1(n)
  REAL(r_dble) :: wrk2(n)
  INTEGER :: ierr,i,j
  REAL(r_dble) :: trace, sum

  a8 = a
  eivec8 = 0.0d0
  error_flag = 0
  
  !print*, "AAA"
! CALL rs(n,n,a8,eival8,imode,eivec8,wrk1,wrk2,ierr)

  eivec8(:,:) = a(:,:)
  
  CALL kaiser(eivec8, n, n, eival8, trace, sum, ierr)
  
  IF( ierr/=0 ) THEN
    WRITE(6,FMT='(A,I2)') '!!! ERROR (mtx_eigen): KAISER error code is ',ierr
    STOP 2
  END IF
  !print*, "BBB"
  nrank_eff = n
  IF( eival8(n) > 0 ) THEN
    DO i=1,n
      IF( eival8(i) < ABS(eival8(n))*SQRT(EPSILON(eival8)) ) THEN
        nrank_eff = nrank_eff - 1
        eival8(i) = 0.0d0
        eivec8(:,i) = 0.0d0
      END IF
    END DO
  ELSE
    WRITE(6,'(A)') '!!! ERROR (mtx_eigen): All Eigenvalues are below 0'
    error_flag = -1
    RETURN
  END IF
  !print*, "CCC"
  IF( nrank_eff<n .AND. eival8(1)/=0 ) THEN
    j = 0
    DO i=n,1,-1
      IF( eival8(i) == 0 ) THEN
        eival8(i) = eival8(n-nrank_eff-j)
        eivec(:,i) = eivec8(:,n-nrank_eff-j)
        eival8(n-nrank_eff-j) = 0.0d0
        eivec8(:,n-nrank_eff-j) = 0.0d0
        j = j+1
      END IF
    END DO
  END IF
  !print*, "DDD"
  DO i=1,n
    eival(i) = eival8(n+1-i)
    eivec(:,i) = eivec8(:,n+1-i)
  END DO

  RETURN
END SUBROUTINE mtx_eigen
!=======================================================================
!  Real symmetric matrix inversion using subroutine dspdi
!    INPUT
!      INTEGER :: n               : dimension of matrix
!      REAL(r_size) :: a(n,n)     : input matrix (real symmetric)
!    OUTPUT
!      REAL(r_size) :: ainv(n,n)  : inverse of a
!=======================================================================
SUBROUTINE mtx_inv(n,a,ainv)
  IMPLICIT NONE

  INTEGER,INTENT(IN) :: n
  REAL(r_size),INTENT(IN) :: a(1:n,1:n)
  REAL(r_size),INTENT(OUT) :: ainv(1:n,1:n)

  REAL(r_dble) :: acmp(n*(n+1)/2)
  REAL(r_dble) :: det(2)
  REAL(r_dble) :: work(n)
  INTEGER :: kpvt(n)
  INTEGER :: inert(3)
  INTEGER :: info
  INTEGER :: i,j,k

  IF(n==1) THEN
    ainv(1,1) = 1.0d0 / a(1,1)
  ELSE

!-----------------------------------------------------------------------
!  Packed form of matrix
!-----------------------------------------------------------------------
  k=0
  DO j=1,n
    DO i=1,j
      k = k+1
      acmp(k) = a(i,j)
    END DO
  END DO
!-----------------------------------------------------------------------
!  dspfa
!-----------------------------------------------------------------------
  CALL dspfa(acmp,n,kpvt,info)
  IF(info /= 0) THEN
    WRITE(6,FMT='(A,I2)') '!!! ERROR (mtx_inv): dspfa error code is ',info
    STOP 3
  END IF
!-----------------------------------------------------------------------
!  dspdi
!-----------------------------------------------------------------------
  CALL dspdi(acmp,n,kpvt,det,inert,work,001)
!-----------------------------------------------------------------------
!  unpack matrix
!-----------------------------------------------------------------------
  k=0
  DO j=1,n
    DO i=1,j
      k = k+1
      ainv(i,j) = acmp(k)
    END DO
  END DO

  DO j=1,n
    DO i=j+1,n
      ainv(i,j) = ainv(j,i)
    END DO
  END DO

  END IF

  RETURN
END SUBROUTINE mtx_inv
!=======================================================================
!  Compute square root of real symmetric matrix
!    INPUT
!      INTEGER :: n                : dimension of matrix
!      REAL(r_size) :: a(n,n)      : input matrix (real symmetric)
!    OUTPUT
!      REAL(r_size) :: a_sqrt(n,n) : square root of a
!=======================================================================
SUBROUTINE mtx_sqrt(n,a,a_sqrt)
  IMPLICIT NONE

  INTEGER,INTENT(IN) :: n
  REAL(r_size),INTENT(IN) :: a(1:n,1:n)
  REAL(r_size),INTENT(OUT) :: a_sqrt(1:n,1:n)

  REAL(r_size) :: eival(n)   ! holds eivenvalue of a
  REAL(r_size) :: eivec(n,n) ! holds eivenvector of a
  REAL(r_size) :: wk(n,n)
  INTEGER :: i,j,k
  INTEGER :: error_flag

  CALL mtx_eigen(1, n, a, eival, eivec, i, error_flag)
  
  IF( error_flag == -1 ) THEN
    DO i=1,n
        wk(:,i)     = 0.0
        a_sqrt(:,i) = 0.0
    END DO
    RETURN
  ENDIF

  DO i=1,n
    wk(:,i) = eivec(:,i) * SQRT( eival(i) )
  END DO

!  a_sqrt = matmul(wk,transpose(eivec))
  DO j=1,n
    DO i=1,n
      a_sqrt(i,j) = wk(i,1)*eivec(j,1)
      DO k=2,n
        a_sqrt(i,j) = a_sqrt(i,j) + wk(i,k)*eivec(j,k)
      END DO
    END DO
  END DO

  RETURN
END SUBROUTINE mtx_sqrt
!=======================================================================
!  Compute inverse of a real matrix (not necessarily symmetric)
!    INPUT
!      INTEGER :: n            : dimension of matrix
!      REAL(r_size) :: aa(n,n) : input matrix (real symmetric)
!    OUTPUT
!      REAL(r_size) :: ff(n,n) : square root of a
!*** COPIED FROM 'A0568.NEW.FORT(MTXINV)' ON 1989.10.1
!    changed to free format by H.Yoshimura 2000.06.27
!    adapted by T.Miyoshi on 2005.10.31
!=======================================================================
SUBROUTINE mtx_inv_rg(n,aa,ff)
!
!##  MATRIX INVERSION
!##  AA IS THE MATRIX TO BE INVERTED
!##  FF IS THE INVERSE OF AA
!
  INTEGER,INTENT(IN) :: n
  REAL(r_size),INTENT(IN) :: aa(n,n)
  REAL(r_size),INTENT(OUT) :: ff(n,n)
!
  REAL(r_size) :: a(n,n)
  REAL(r_size) :: b(n,n)
  REAL(r_size) :: x(n,n)
!
  REAL(r_size) :: c,cc,xx
  INTEGER :: i,j,n1,k,kp,jx,ii,jr,jp
!-------------------------------------------------------
  n1=n-1
!
  do i=1,n
    do j=1,n
      a(i,j)=aa(i,j)
    end do
  end do
!
  do i=1,n
    do j=1,n
      b(i,j)=0.d0
      if( i == j ) b(i,j)=1.d0
    end do
  end do
!
  do j=1,n
    c=abs(a(1,j))
    do i=2,n
      c=max(c,abs(a(i,j)))
    end do
    c=1.d0/c
    do i=1,n
      a(i,j)=a(i,j)*c
    end do
    b(j,j)=b(j,j)*c
  end do
!
  do k=1,n1
    c=abs(a(k,k))
    kp=k+1
    jx=k
    do j=kp,n
      cc=abs(a(k,j))
      if ( cc < c ) cycle
      c=cc
      jx=j
    end do
    do i=k,n
      c=a(i,k)
      a(i,k)=a(i,jx)
      a(i,jx)=c
    end do
    do i=1,n
      c=b(i,k)
      b(i,k)=b(i,jx)
      b(i,jx)=c
    end do
    do j=kp,n
      c=a(k,j)/a(k,k)
      do ii=1,n
        b(ii,j)=b(ii,j)-c*b(ii,k)
      end do
      do i=k,n
        a(i,j)=a(i,j)-c*a(i,k)
      end do
    end do
  end do
!
  do ii=1,n
    x(ii,n)=b(ii,n)/a(n,n)
    do j=1,n1
      jr=n-j
      jp=jr+1
      xx=0.d0
      do i=jp,n
        xx=xx+a(i,jr)*x(ii,i)
      end do
      x(ii,jr)=(b(ii,jr)-xx)/a(jr,jr)
    end do
  end do
!
  do i=1,n
    do j=1,n
      ff(i,j)=x(i,j)
    end do
  end do
!
END SUBROUTINE mtx_inv_rg

SUBROUTINE kaiser(a, nrows, n, eigenv, trace, sume, ier)

!  EIGENVALUES AND VECTORS OF A SYMMETRIC +VE DEFINITE MATRIX,
!  USING KAISER'S METHOD.
!  REFERENCE: KAISER,H.F. 'THE JK METHOD: A PROCEDURE FOR FINDING THE
!  EIGENVALUES OF A REAL SYMMETRIC MATRIX', COMPUT.J., VOL.15, 271-273, 1972.

!  ARGUMENTS:-
!  A       = INPUT, AN ARRAY CONTAINING THE MATRIX
!            OUTPUT, THE COLUMNS OF A CONTAIN THE NORMALIZED EIGENVECTORS
!            OF A.   N.B. A IS OVERWRITTEN !
!  NROWS   = INPUT, THE FIRST DIMENSION OF A IN THE CALLING PROGRAM.
!  N       = INPUT, THE ORDER OF A, I.E. NO. OF COLUMNS.
!            N MUST BE <= NROWS.
!  EIGENV()= OUTPUT, A VECTOR CONTAINING THE ORDERED EIGENVALUES.
!  TRACE   = OUTPUT, THE TRACE OF THE INPUT MATRIX.
!  SUME    = OUTPUT, THE SUM OF THE EIGENVALUES COMPUTED.
!            N.B. ANY SYMMETRIC MATRIX MAY BE INPUT, BUT IF IT IS NOT +VE
!            DEFINITE, THE ABSOLUTE VALUES OF THE EIGENVALUES WILL BE FOUND.
!            IF TRACE = SUME, THEN ALL OF THE EIGENVALUES ARE POSITIVE
!            OR ZERO.   IF SUME > TRACE, THE DIFFERENCE IS TWICE THE SUM OF
!            THE EIGENVALUES WHICH HAVE BEEN GIVEN THE WRONG SIGNS !
!  IER     = OUTPUT, ERROR INDICATOR
!             = 0 NO ERROR
!             = 1 N > NROWS OR N < 1
!             = 2 FAILED TO CONVERGE IN 10 ITERATIONS

!  LATEST REVISION - 6 September 1990
!  Fortran 90 version - 20 November 1998

!*************************************************************************

IMPLICIT NONE

!!!INTEGER, PARAMETER :: dp = SELECTED_REAL_KIND(14, 60)

INTEGER, INTENT(IN)       :: nrows
INTEGER, INTENT(IN)          :: n

REAL (r_dble), INTENT(INOUT) :: a(:,:)
REAL (r_dble), INTENT(OUT)   :: eigenv(:)
REAL (r_dble), INTENT(OUT)   :: trace
REAL (r_dble), INTENT(OUT)   :: sume

INTEGER, INTENT(OUT)         :: ier

! Local variables

INTEGER   :: i, iter, j, k, ncount, nn

REAL (r_dble), PARAMETER :: small = 1.0e-12_r_dble, &
                            zero  = 0.0_r_dble,     &
                            half  = 0.5_r_dble,     &
                            one   = 1.0_r_dble
                            

REAL (r_dble) :: absp, absq, COS, ctn, eps, halfp, p, q, SIN, ss, TAN, temp, xj, xk

!   CALCULATE CONVERGENCE TOLERANCE, EPS.
!   CALCULATE TRACE.   INITIAL SETTINGS.

ier = 1
IF(n < 1 .OR. n > nrows) RETURN
ier = 0
iter = 0
trace = zero
ss = zero
DO j = 1,n
  trace = trace + a(j,j)
  DO i = 1,n
    ss = ss + a(i,j)**2
  END DO
END DO
sume = zero
eps = small*ss/n
nn = n*(n-1)/2
ncount = nn

!   ORTHOGONALIZE PAIRS OF COLUMNS J & K, K > J.

20 DO j = 1,n-1
  DO k = j+1,n
    
!   CALCULATE PLANAR ROTATION REQUIRED
    
    halfp = zero
    q = zero
    DO i = 1,n
      xj = a(i,j)
      xk = a(i,k)
      halfp = halfp + xj*xk
      q = q + (xj+xk) * (xj-xk)
    END DO
    p = halfp + halfp
    absp = ABS(p)
    
!   If P is very small, the vectors are almost orthogonal.
!   Skip the rotation if Q >= 0 (correct ordering).
    
    IF (absp < eps .AND. q >= zero) THEN
      ncount = ncount - 1
      IF (ncount <= 0) GO TO 160
      CYCLE
    END IF
    
!   Rotation needed.
    
    absq = ABS(q)
    IF(absp <= absq) THEN
      TAN = absp/absq
      COS = one/SQRT(one + TAN*TAN)
      SIN = TAN*COS
    ELSE
      ctn = absq/absp
      SIN = one/SQRT(one + ctn*ctn)
      COS = ctn*SIN
    END IF
    COS = SQRT((one + COS)*half)
    SIN = SIN/(COS + COS)
    IF(q < zero) THEN
      temp = COS
      COS = SIN
      SIN = temp
    END IF
    IF(p < zero) SIN = -SIN
    
!   PERFORM ROTATION
    
    DO i = 1,n
      temp = a(i,j)
      a(i,j) = temp*COS + a(i,k)*SIN
      a(i,k) = -temp*SIN + a(i,k)*COS
    END DO
  END DO
END DO
ncount = nn
iter = iter + 1
IF(iter < 10) GO TO 20
ier = 2

!   CONVERGED, OR GAVE UP AFTER 10 ITERATIONS

160 DO j = 1,n
  temp = SUM( a(1:n,j)**2 )
  eigenv(j) = SQRT(temp)
  sume = sume + eigenv(j)
END DO

!   SCALE COLUMNS TO HAVE UNIT LENGTH

DO j = 1,n
  IF (eigenv(j) > zero) THEN
    temp = one/eigenv(j)
  ELSE
    temp = zero
  END IF
  a(1:n,j) = a(1:n,j)*temp
END DO

RETURN
END SUBROUTINE kaiser

END MODULE common_mtx

subroutine mean_stddev(a,nx,mean,stddev)

  integer nx
  real*8 a(nx)
  real*8 mean, stddev

  mean   = 0.0d0
  stddev = 0.0d0
  IF( nx > 1 ) THEN
    mean   = SUM( a ) / float(nx)
    stddev = SQRT( SUM( (mean*mean - mean*a + a*a) ) / float(nx-1) )
  ELSE
    mean   = a(1)
  ENDIF

return
end subroutine mean_stddev

