 program ahGRB2FST
  use eccodes
  implicit none
 
  integer                            ::  ifile
  integer                            ::  iret
  integer                            ::  igrib
  real                               ::  latitudeOfFirstPointInDegrees
  real                               ::  longitudeOfFirstPointInDegrees
  real                               ::  latitudeOfLastPointInDegrees
  real                               ::  longitudeOfLastPointInDegrees
  integer                            ::  numberOfPointsAlongAParallel
  integer                            ::  numberOfPointsAlongAMeridian
  real, dimension(:), allocatable    ::  buffer
  integer                            ::  numberOfValues
  real                               ::  average,min_val, max_val
  integer                            ::  is_missing
  character(len=10)                  ::  open_mode='r'
  integer                            ::  marsClass   !RB 2019
!
!  FST
!
  integer ier, iunit, fnom, fclos, fstouv, fstecr, fstfrm, newdate, readstat, endofnml
  external fnom, fclos, fstouv, fstecr, fstfrm, newdate, cxgaig, flipOnJ
  character (len=160) ifileFST, fname   ! to match length of fst name in namelist
  parameter (iunit=1)
  real, dimension(:,:), allocatable  ::  work   , work2
  integer npak, bdateo, deet, &
          npas, ni, nj, ip1, ip2, ip3, ig1, ig2, ig3, ig4
  character *12, etiket
  character *4, nomvar
  character *1, grtyp
  parameter (npak=-16, grtyp='X',deet=0)
  integer level, dataDate, dataTime, i, j
!  character *4, shortName
  character *5, shortName  !ewss  ???
  character *160, cfName, units, gridType, grib, fst, outdir, rootfst,ligne  ! watch out file names shorter than 160 char
  real xlat0, xlon0, dlat, dlon, zeroCelsius, grav
  parameter (grav=9.80665, zeroCelsius= 273.15)
  integer verbose
!  parameter (verbose=0)  
  logical outgridspecs
!  data (grib='',outgridspecs=.t.,ip2=0, ip3=0, outdir='.')
  integer months(2)
  integer maxcatch, ncatch2d, ncatch3d
  parameter (maxcatch=100)  
  character *4, catch2d(maxcatch), catch3d(maxcatch)
  logical catchit
  namelist /controls/ grib, fst, verbose, outdir, outgridspecs, &
                      ip2, ip3, etiket, months, rootfst, &
                      catch2d, catch3d

  integer maxdict
  parameter (maxdict=100)
  character *4, shortNames(maxdict), nomvars(maxdict)
  character *10, grbunits(maxdict), fstunits(maxdict)
  character *2, is2D3D(maxdict)
  real   mults(maxdict), adds(maxdict)
  integer idict, ndict
!
  print *,'********************************'
  print *,'*                              *'
  print *,'* ad-hoc GRIB to FST converter *'
  print *,'* for ERA-I grib files         *'
  print *,'*                              *'
  print *,'********************************'

  grib=''
  fst=''
  outgridspecs=.true.
  ip2=0 
  ip3=0
  outdir='.'
  verbose=0 !0-1-2
  !RB 2019 adjust etiket to either ERAI or ERA5 depending 
  !  on grib source key marsClass (=14 for ERA Interim; =23 for ERA5)
  etiket='' !'ERA-I_to_FST'  ! to be defined in messages loop
  months=0  ! user can specify start and end month (2 values)
  rootfst=''
  catch2d(:)=''
  catch3d(:)=''

  read (5, nml=controls)
  write (6,nml=controls)
  ifileFST=trim(fst)
  if (trim(grib) .eq. '') then
    print *,'must provide grib file name in key grib=''...''. stopping'
    stop
  endif
  !
! compter les catch 2d 3d
  ncatch2d=0
  j=0
  do i=1,maxcatch
  if (catch2d(i).ne.'') j=j+1
  end do
  ncatch2d=j
  ncatch3d=0
  j=0
  do i=1,maxcatch
  if (catch3d(i).ne.'') j=j+1
  end do
  ncatch3d=j
  print *,'ncatch2d=',ncatch2d,'ncatch3d=',ncatch3d  

  open (unit=1,file='ahdict',form='formatted')
  readstat=0
  i=0
  idict=0
  do while (readstat .eq. 0)
  i=i+1
  if (i.eq.1) then
  	print *, 'DICTIONNARY:'
  	read (1,'(a)',iostat=readstat) ligne
	print *,'          #  ', trim(ligne)
  else
	idict=idict+1
	if (idict.gt.maxdict) then
		print *,'too many lines in dictionnary. max allowed is ',maxdict
		stop
	endif
	read (1,*,iostat=readstat) shortNames(idict),grbunits(idict), &
	is2D3D(idict),nomvars(idict),fstunits(idict),mults(idict),adds(idict)
	if (readstat.eq.0) then
		print *,idict,shortNames(idict),grbunits(idict), &
		is2D3D(idict),nomvars(idict),fstunits(idict),mults(idict),adds(idict)
	else
		idict=idict -1
	endif
  endif
!  if (i .gt.endofnml .and. readstat .eq.0) then
!	print '(i3,1x,a)',i, trim(ligne)
!  endif
  end do
  ndict=idict
  print *, 'dictionnary size is:',ndict
  close(1)
  
  call codes_open_file(ifile, &
       trim(grib), open_mode)

  ier = fnom( iunit, ifileFST, 'STD+RND+R/W', 0)
  if ( ier .lt. 0 ) then
     print *, 'Error while linking the file:', trim(ifileFST)
     stop
  else
     print *, 'FST ',trim(ifileFST), ' opened'
  endif
  ier = fstouv( iunit, 'STD+RND' )
  if ( ier .lt. 0 ) then
     print *, 'Cannot open the file:', trim(ifileFST)
     stop
  endif

!  ip3=-1
	marsClass=-1  !RB 2019
  ! Loop on all the messages in a file.
 
  ! A new GRIB message is loaded from file
  ! igrib is the grib id to be used in subsequent calls
  call  codes_grib_new_from_file(ifile,igrib, iret)
 
  LOOP: DO WHILE (iret /= CODES_END_OF_FILE)
 
    ! Check if the value of the key is MISSING
    is_missing=0;
    call codes_is_missing(igrib,'Ni',is_missing);
    if ( is_missing /= 1 ) then
        ! Key value is not missing so get as an integer
        call codes_get(igrib,'Ni',numberOfPointsAlongAParallel)
        if (verbose .eq. 2) then 
         write(*,*) 'numberOfPointsAlongAParallel=', numberOfPointsAlongAParallel 
        endif
    else
        write(*,*) 'numberOfPointsAlongAParallel is missing'
    endif
    !RB 2019 adjust etiket to either ERAI or ERA5 depending 
    !  on grib source key marsClass (=14 for ERA Interim; =23 for ERA5)
    call codes_get(igrib,'marsClass',marsClass)
    select case (marsClass)
    	case(14)
    		etiket='FSTfrom_ERAI'
 		case(23)
 			etiket='FSTfrom_ERA5'
		case default
			! unsupported
			write(*,*) 'marsClass not available or unsupported:',marsClass
			call exit
	 end select			
    ! Get as an integer
    call codes_get(igrib,'Nj',numberOfPointsAlongAMeridian)
    if (verbose .eq. 2) then 
    write(*,*) 'numberOfPointsAlongAMeridian=', numberOfPointsAlongAMeridian
    endif 
    ! Get as a real
    call codes_get(igrib, 'latitudeOfFirstGridPointInDegrees', &
          latitudeOfFirstPointInDegrees)
        if (verbose .eq. 2) then 
        write(*,*) 'latitudeOfFirstGridPointInDegrees=',latitudeOfFirstPointInDegrees
        endif
    ! Get as a real
    call codes_get(igrib, 'longitudeOfFirstGridPointInDegrees', &
          longitudeOfFirstPointInDegrees)
        if (verbose .eq. 2) then 
        write(*,*) 'longitudeOfFirstGridPointInDegrees=',longitudeOfFirstPointInDegrees
        endif
    ! Get as a real
    call codes_get(igrib, 'latitudeOfLastGridPointInDegrees', &
          latitudeOfLastPointInDegrees)
        if (verbose .eq. 2) then 
        write(*,*) 'latitudeOfLastGridPointInDegrees=',latitudeOfLastPointInDegrees
        endif
    ! Get as a real
    call codes_get(igrib, 'longitudeOfLastGridPointInDegrees', &
          longitudeOfLastPointInDegrees)
        if (verbose .eq. 2) then 
        write(*,*) 'longitudeOfLastGridPointInDegrees=',longitudeOfLastPointInDegrees
        endif
    ! Get the size of the values array
    call codes_get_size(igrib,'values',numberOfValues)
        if (verbose .eq. 2) then 
        write(*,*) 'numberOfValues=',numberOfValues
        endif
    ni=numberOfPointsAlongAParallel
    nj=numberOfPointsAlongAMeridian
 
    allocate(buffer(ni*nj), stat=iret)  !numberOfValues
    ! Get data values
    call codes_get(igrib,'values',buffer)
    call codes_get(igrib,'min',min_val) ! can also be obtained through minval(values)
    call codes_get(igrib,'max',max_val) ! can also be obtained through maxval(values)
    call codes_get(igrib,'average',average) ! can also be obtained through maxval(values)
!
!  write values to FST
!
    call codes_get(igrib,'level',level)
    call codes_get(igrib,'shortName',shortName)
    call codes_get(igrib,'dataDate',dataDate)
    call codes_get(igrib,'dataTime',dataTime)
    call codes_get(igrib,'units',units)
!
!  grid descriptors
!
    call codes_get(igrib,'gridType',gridType)
!
!
    print *,'Read GRIB ',shortName,ni,nj,dataDate,dataTime,level,trim(gridType)
!
    if (trim(gridType) .eq. 'regular_ll') then
    xlat0=latitudeOfLastPointInDegrees  ! grib array do need to be flipped n-south
    xlon0=longitudeOfFirstPointInDegrees
    call codes_get(igrib,'jDirectionIncrementInDegrees',dlat) 
    call codes_get(igrib,'iDirectionIncrementInDegrees',dlon) 
    if (verbose .ge. 1) then 
    print *,'xlat0, xlon0, dlat, dlon: ', xlat0, xlon0, dlat, dlon
    endif
    CALL CXGAIG('L', IG1, IG2, IG3, IG4, xlat0, xlon0, dlat, dlon)
!
    else
    print *,'wrong gridType :',gridType,' stopping'
    endif
    if (verbose .ge. 1) then 
    print *,'shortName,date,time,gridType: ',shortName,dataDate,dataTime*10000,trim(gridType)
    endif
    allocate(work(ni,nj), stat=iret) !numberOfValues
! flip N/S
    work2=reshape(buffer,(/ni,nj/))
!    work=work2(:,nj:-1:1)
    do j=1,nj
    do i=1,ni
     buffer(i+(j-1)*ni)=work2(i,nj+1-j)  !flipping
    enddo
    enddo
    
!    buffer=reshape(work(:,nj:-1:1),numberOfValues)
!
!  scaling etc which is dependent upon the shortName and its units
!
!    call flipOnJ(buffer,work,ni,nj)

! do we want to catch this record ?
  catchit=.false.
	do i=1,ncatch2d
		if (index(catch2d(i),trim(shortName)).gt.0) catchit=.true.
	end do
	do i=1,ncatch3d
		if (index(catch3d(i),trim(shortName)).gt.0) catchit=.true.
	end do

  if (catchit) then
	  j=0
	  do i=1,ndict
		if (index(shortNames(i),trim(shortName)).gt.0) then
			if ((level.gt.0 .and. is2d3d(i).eq.'3D').or.(level.eq.0 .and. is2d3d(i).eq.'2D')) then
				j=i
			endif
		endif
	  end do
	  if (j.gt.0) then
	  	! convertir unites
	  	buffer=mults(j)*buffer+adds(j)
	  	nomvar=nomvars(j)
	  else
	  	print *,'shortName : ',shortName,' not allowed. stop'
		stop
	  endif
  endif

  
  if (catchit) then
    if (is2d3d(j).eq.'3D') then
    	ip1= level  !pressure level tag
 	else
 		ip1=0
	endif
	
    ier=newdate (bdateo,dataDate,dataTime*10000, 3)  ! x10000 to have the seconds
    ier = fstecr( buffer, work, npak, iunit, bdateo, deet, &
          npas, ni, nj, 1, ip1, ip2, ip3, &
          'A', nomvar, etiket, 'L', &
          ig1,ig2,ig3,ig4, 1, .false. )  !true
  endif

    deallocate(buffer)
!    deallocate(work)
 
    if (verbose .eq. 2) then 
    write(*,*)'There are ',numberOfValues, &
          ' average is ',average, &
          ' min is ',  min_val, &
          ' max is ',  max_val
    endif 
    call codes_release(igrib)
 
    call codes_grib_new_from_file(ifile,igrib, iret)
 
  end do LOOP
  
! prepare de grid settings file for the WEST classification program
  call grid_gen(fst,ni,nj,dlat,dlon,xlat0,xlon0)
! 
  call codes_close_file(ifile)
 
  ier = fstfrm(iunit)
  ier = fclos(iunit)

 end program ahGRB2FST
 
      subroutine grid_gen  (fst,ni,nj,dlat,dlon,xlat0,xlon0)
      implicit none
      character*(*) fst  !careful fst is 160 long in main
      integer ni,nj
      real dlat,dlon,xlat0,xlon0
!
!*** import namelist ****
!
include "comdecks/grid.cdk"
!
      integer unnml, k, status
      parameter ( unnml = 10 )
      character*170 nml
!
      namelist /grille/ Grd_proj_S, Grd_ni, Grd_nj, &
                          Grd_iref, Grd_jref, Grd_latr, Grd_lonr, &
                          Grd_dx, Grd_dgrw, Grd_phir, &
                          Grd_xlat1, Grd_xlon1, Grd_xlat2, Grd_xlon2
      character*160 string1,string2 
!      
      if (dlat.ne.dlon) then
        print *, 'this case is not supported.  dlat .ne. dlon'
      print *, dlat, dlon
      stop "dlat different from dlon"
      endif
!
      call split_string(fst,string1,string2,'.')
      nml = trim(string1)//'_settings.nml'  !'grid_cfg'
      print *,'settings file:',nml
!     
      open ( unnml, file=nml, access='sequential', &
     &       form='formatted', status='replace', iostat=status )
      if ( status .ne. 0 ) then
         print *, 'FILE ', trim(nml), ' NOT FOUND'  !RB 2018
         stop
      endif
!      
      Grd_proj_S='L'
	Grd_ni= ni
	Grd_nj= nj
	Grd_iref= 1
	Grd_jref= 1
	Grd_latr= xlat0
	Grd_lonr= xlon0
	Grd_dx= dlat
!  pour les xlat xlon ici valeurs pour axes geo vrais.  PAS toucher cidessous	
	Grd_dgrw= 0.0
	Grd_phir= 0.0
	Grd_xlat1= 0.0
	Grd_xlon1= 180.0
	Grd_xlat2= 0.0
	Grd_xlon2= 270.
!      
      write ( unnml, nml=grille )
      close ( unnml )
      return
      end subroutine grid_gen
      
  ! split a string into 2 either side of a delimiter token
  SUBROUTINE split_string(instring, string1, string2, delim)
    CHARACTER*(*) :: instring
    character(1)  delim
    CHARACTER(160),INTENT(OUT):: string1,string2
    INTEGER :: index

    instring = TRIM(instring)

    index = SCAN(instring,delim)
    string1 = instring(1:index-1)
    string2 = instring(index+1:)

  END SUBROUTINE split_string      

