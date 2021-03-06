C      SUBROUTINE NNLS - SEE LAWSON AND HANSON'S TEXT ON SOLVING
C      LEAST SQUARES (pp. 304-307).  THIS IS THE SUBROUTINE USED
C      IN MATLAB.
C
C      GIVEN AN M BY N MATRIX A, AND AN M BY 1 VECTOR B, COMPUTE
C      AN N BY 1 VECTOR X, WHICH SOLVES THE LEAST SQUARES PROBLEM
C
C                A * X = B SUBJECT TO X .GE. 0
C
C      A(),MDA,M,N      MDA IS THE FIRST DIMENSIONING PARAMETER
C                       FOR THE ARRAY, A().  ON ENTRY A() CONTAINS
C                       THE M BY N MATRIX A.  ON EXIT A() CONTAINS
C                       THE PRODUCT MATRIX Q*A, WHERE Q IS AN
C                       M BY M ORTHOGONAL MATRIX GENERATED
C                       IMPLICITLY BY THE SUBROUTINE.
C      B()       ON ENTRY B() CONTAINS THE VECTOR B AND ON EXIT
C                IT CONTAINS Q*B.
C      X()       ON ENTRY X() NEED NOT BE INITIALIZED.  ON EXIT
C                THIS WILL BE THE SOLUTION VECTOR.
C      RESNORM   ON EXIT RESNORM CONTAINS THE EUCLIDEAN NORM OF THE 
C                RESIDUAL VECTOR.
C      W()       AN N-ARRAY OF WORKING SPACE.  ON EXIT W() CONTAINS 
C                THE DUAL SOLUTION VECTOR.  W WILL SATISFY W(I)=0
C                FOR ALL I IN SET P AND W(I) .LE. 0 FOR AL I IN SET Z.
C      ZZ()      AN M-ARRAY FOR WORKING SPACE
C      INDX()    AN INTEGER WORKING ARRAY OF LENGTH AT LEAST N.
C                ON EXIT THE CONTENTS OF THIS ARRAY DEFINE THE SETS
C                P AND Z AS FOLLOWS.
C
C                    INDX(1) THRU INDX(NSETP)=SET P.
C                    INDX(IZ1) THRU INDX(IZ2)=SET Z.
C                    IZ1=NSETP+1=NPP1
C                    IZ2=N
C      MDE      THIS IS A SUCCESS-FAILURE FLAG WITH THE FOLLOWING 
C                MEANINGS.
C                1     THE SOLUTION HAS BEEN COMPUTED SUCCESSFULLY
C                2     THE DIMESNIONS OF THE PROBLEM ARE BAD
C                      EITHER M .LE. 0 OR N .LE 0
C                3     ITERATION COUNT EXCEEDED
C
      SUBROUTINE NNLS (A,MDA,M, N,B,X,RESNORM,W,ZZ,INDX,MDE)
      DIMENSION A(MDA,N), B(M), X(N), W(N), ZZ(M)
      REAL A,B,X,RESNORM,W,ZZ
      INTEGER INDX(N),ITER,NSETP
      ZERO=0.
      ONE=1.
      TWO=2.
      FACTOR=0.01
      MDE=1
      IF (M.GT.0 .AND. N.GT.0) GO TO 10
      MDE=2
      RETURN
 10   ITER=0
      ITMAX=3*N
C
C     INITIALIZE THE ARRAYS  INDX() AND X()
C
         DO 20 I=1,N
         X(I)=ZERO
 20      INDX(I)=I
C
      IZ2=N
      IZ1=1
      NSETP=0
      NPP1=1
C
C     ********MAIN LOOP BEGINS HERE***********
 30   CONTINUE
C
C     QUIT IF ALL COEFFICIENTS ARE ALREADY IN THE SOLUTION
C     OR IF M COLS OF A HAVE BEEN TRIANGULARIZED.
C
      IF (IZ1.GT.IZ2 .OR. NSETP.GE.M) GO TO 350
C
C     COMPUTE COMPONENTS OF THE DUAL (NEGATIVE GRADIENT) VECTOR W()
C
          DO 50 IZ=IZ1,IZ2
          J=INDX(IZ)
          SM=ZERO
                DO 40 L=NPP1,M
 40             SM=SM+A(L,J)*B(L)
 50       W(J)=SM
C
C         FIND LARGEST POSITIVE W(J)
C
 60   WMAX=ZERO
          DO 70 IZ=IZ1,IZ2
          J=INDX(IZ)
          IF (W(J).LE.WMAX) GO TO 70
          WMAX=W(J)
          IZMAX=IZ
 70       CONTINUE
C
C     IF WMAX .LE. O GO TO TERMINATION
C     THIS INDICATES SATISFACTION OF THE KUHN-TUCKER CONDITIONS
C
      IF (WMAX) 350,350,80
 80   IZ=IZMAX
      J=INDX(IZ)
C
C     THE SIGN OF W(J) IS OK FOR J TO BE MOVED TO SET P
C     BEGIN THE TRANSFORMATION AND CHECK NEW DIAGONAL ELEMENT TO
C     AVOID NEAR LINEAR DEPENDENCE.
C
      ASAVE=A(NPP1,J)
      CALL H12 (1,NPP1,NPP1+1,M,A(1,J),1,UP,DUMMY,1,1,0)
      UNORM=ZERO
      IF (NSETP.EQ.0) GO TO 100
           DO 90 L=1,NSETP
 90        UNORM=UNORM+A(L,J)**2
 100  UNORM=SQRT(UNORM)
      IF (DIFF(UNORM+ABS(A(NPP1,J))*FACTOR,UNORM)) 130,130,110
      
C
C     COL J IS SUFFICIENTLY INDEPENDENT.  COPY B INTO ZZ. UPDATE ZZ
C     AND SOLVE FOR ZTEST (=PROPOSED NEW VALUE FOR X(J)).
C
 110       DO 120 L=1,M
 120       ZZ(L)=B(L)
      CALL H12(2,NPP1,NPP1+1,M,A(1,J),1,UP,ZZ,1,1,1)
      ZTEST=ZZ(NPP1)/A(NPP1,J)
C
C      SEE IF ZTEST IS POSITIVE
C
      IF (ZTEST) 130,130,140
C
C     REJECT J AS A CANDIDATE TO BE MOVED FROM SET Z TO SET P.
C     RESTORE A(NPP1,J), SET W(J)=0., AND LOOP BACK TO TEST DUAL
C     COEFFS AGAIN.
C
 130  A(NPP1,J)=ASAVE
      W(J)=ZERO
      GO TO 60
C
C     THE INDEX J=INDX(IZ) HAS BEEN SELECTED TO BE MOVED FROM 
C     SET Z TO SET P.  UPDATE B. UPDATE INDICES. APPLY HOUSEHOLDER
C     TRANSFORMATIONS TO COLS IN NEW SET Z.  ZERO SUBDIAGONAL ELTS IN
C     COL J, SET W(J)=0.
C
 140      DO 150 L=1,M
 150      B(L)=ZZ(L)
C
      INDX(IZ)=INDX(IZ1)
      INDX(IZ1)=J
      IZ1=IZ1+1
      NSETP=NPP1
      NPP1=NPP1+1
C
      IF (IZ1.GT.IZ2) GO TO 170
          DO 160 JZ=IZ1,IZ2
          JJ=INDX(JZ)
 160      CALL H12 (2,NSETP,NPP1,M,A(1,J),1,UP,A(1,JJ),1,MDA,1)
 170  CONTINUE
C
      IF (NSETP.EQ.M) GO TO 190
          DO 180 L=NPP1,M
 180      A(L,J)=ZERO
 190  CONTINUE
C
      W(J)=ZERO
C
C     SOLVE THE TRIANGULAR SYSTEM, AND STORE THE SOLUTION
C     TEMPORARILY IN ZZ()
      TEST=-4.
      GO TO 400
 200  CONTINUE
C
C     ***********SECONDARY LOOP BEGINS HERE*************
C
C                    ITERATION COUNTER
C
 210  ITER=ITER+1
      IF (ITER.LE.ITMAX) GO TO 220
      MDE=3
      GO TO 350
 220  CONTINUE
C
C     SEE IF ALL NEW CONSTRAINED COEFFS ARE FEASIBLE
C     IF NOT, COMPUTE ALPHA
C
      ALPHA=TWO
          DO 240 IP=1,NSETP
          L=INDX(IP)
          IF(ZZ(IP)) 230,230,240
C
 230      T=-X(L)/(ZZ(IP)-X(L))
          IF (ALPHA.LE.T) GO TO 240
          ALPHA=T
          JJ=IP
 240      CONTINUE
     
C
C      IF ALL NEW CONSTRAINED COEFFS ARE FEASIBLE THEN ALPHA WILL
C      STILL = 2.  IF SO EXIT FROM SECONDARY LOOP TO MAIN LOOP
C
      IF (ALPHA.EQ.TWO) GO TO 330
C
C      OTHERWISE USE ALPHA, WHICH WILL BE BETWEEN 0. AND 1. TO 
C      INTERPOLATE BETWEEN THE OLD X AND THE NEW ZZ
C
          DO 250 IP=1,NSETP
          L=INDX(IP)
       X(L)=X(L)+ALPHA*(ZZ(IP)-X(L))
 250   CONTINUE   
C
C      MODIFY A AND B AND THE INDX ARRAYS TO MOVE COEFF 1
C      FROM SET P TO SET Z
C
      I=INDX(JJ)
 260  X(I)=ZERO
C
      IF (JJ.EQ.NSETP) GO TO 290
      JJ=JJ+1
          DO 280 J=JJ,NSETP
          II=INDX(J)
          INDX(J-1)=II
          CALL G1 (A(J-1,II),A(J,II),CC,SS,A(J-1,II))
          A(J,II)=ZERO
                DO 270 L=1,N
                IF (L.NE.II) CALL G2 (CC,SS,A(J-1,L),A(J,L))
 270            CONTINUE
 280      CALL G2 (CC,SS,B(J-1),B(J))
 290  NPP1=NSETP
      NSETP=NSETP-1
      IZ1=IZ1-1
      INDX(IZ1)=I
C
C     SEE IF THE REMAINING COEFFS IN SET P ARE FEASIBLE.  THEY
C     SHOULD BE BECAUSE OF THE WAY ALPHA WAS DETERMINED.
C     IF ANY ARE INFEASIBLE IT IS DUE TO ROUND-OFF ERROR.  ANY
C     THAT ARE NONPOSITIVE WILL BE SET TO ZERO
C     AND MOVED FROM SET P TO SET Z
C
           DO 300 JJ=1,NSETP
           I=INDX(JJ)
           IF (X(I)) 260,260,300
 300       CONTINUE
C
C     COPY B() INTO ZZ().  THEN SOLVE AGAIN AND LOOP BACK.
C
           DO 310 I=1,M
 310       ZZ(I)=B(I)
      TEST=4.
      GO TO 400
 320  CONTINUE
      GO TO 210
C
C      ******************END OF SECONDARY LOOP***************
C
 330        DO 340 IP=1,NSETP
            I=INDX(IP)
 340        X(I)=ZZ(IP)
C
C       ALL NEW COEFFS ARE POSITIVE.  LOOP BACK TO THE BEGINNING
C
      GO TO 30
C
C   *********************END OF MAIN LOOP*********************
C
C    COME TO HERE FOR TERMINATION
C    COMPUTE THE NORM OF THE RESIDUAL VECTOR
 350  SM=ZERO
      IF (NPP1.GT.M) GO TO 370
         DO 360 I=NPP1,M
 360     SM=SM+B(I)**2
      GO TO 390
 370     DO 380 J=1,N
 380     W(J)=ZERO
 390  RESNORM=SQRT(SM)
      RETURN
C
C     THE FOLLOWING BLOCK OF CODE IS USED AS AN INTERNAL
C     SUBPROGRAM TO SOLVE THE TRIANGULAR SYSTEM, PUTTING
C     THE SOLUTION IN ZZ()
 400      DO 430 L=1,NSETP
          IP=NSETP+1-L
          IF (L.EQ.1) GO TO 420
              DO 410 II=1,IP
 410          ZZ(II)=ZZ(II)-A(II,JJ)*ZZ(IP+1)
 420      JJ=INDX(IP)
 430      ZZ(IP)=ZZ(IP)/A(IP,JJ)
       IF (TEST) 200,200,320
       END















