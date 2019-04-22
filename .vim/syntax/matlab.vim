" 	########################### "VIM SYNTAX FILE" ############################
" Language:	Matlab
" Maintainer:	Fabrice Guy <fabrice.guy at gmail dot com>
"		Original authors: Mario Eusebio and Preben Guldberg
" Modifier:	Yaroslav Don
" Last Change:	2008 Oct 16 : added try/catch/rethrow and class statements
" 		2008 Oct 28 : added highlighting for most of Matlab functions
" 		2009 Nov 23 : added 'todo' keyword in the matlabTodo keywords 
" 		(for doxygen support)
" 		2010 Jul 19 : added many statements for syntax highlighting (YD).
" 		2011 Feb 09 : added small changes (YD).

" --- Define Syntax ---
" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

" --- Add Folding Method ---
if has("folding")
   "MY EDIT - don't want any folding, so this is disabled
   "setlocal foldmethod=syntax
endif

" --- Enable Blocks ---
if !exists("s:syntax_block_definitions")
   let s:syntax_block_definitions=1
endif

" --- Use Exception Colour for «try-catch-end» Blocks ---
if !exists("s:use_exception_try_catch")
   let s:use_exception_try_catch=1
endif

" --- Detect End statement for functions ---
if !exists("s:functionWithoutEndStatement")
   let s:functionWithoutEndStatement=0 " default is w/ end
endif

" 	########################### "SYNTAX DEFINITIONS" ############################
" =========== "Basics" ===========
" --- Matlab basic Word ---
syn match matlabWord			'\a\w*' 

" --- Matlab basic Keywords ---
" «enumeration» is from 2010b and on
if s:syntax_block_definitions
   " ... Definitions with Blocks ...
   syn match matlabStatement		'\<function\>'
   syn keyword matlabStatement		return
   syn keyword matlabConditional	else elseif break continue
   syn match matlabConditional		'\<\%(if\|switch\|case\|otherwise\)\>'
   syn match matlabRepeat		'\<\%(parfor\|for\|while\)\>'					| " YD --- removed 'do' statement
   syn match matlabObjectOriented	'\<\%(classdef\|methods\|properties\|events\|enumeration\)\>'	| " YD --- removed matlabScope
   syn keyword matlabScope		persistent global						| " YD --- added
   syn match matlabTryCatch		'\<try\>'
   syn keyword matlabTryCatch		catch
   syn keyword matlabExceptions	rethrow throw
else 
   " ... Simple Definitions ...
   syn keyword matlabStatement		return function
   syn keyword matlabConditional	switch case else elseif if otherwise break continue
   syn keyword matlabRepeat		parfor for while						| " YD --- no do
   syn keyword matlabObjectOriented	classdef methods properties events enumeration			| " YD --- removed matlabScope
   syn keyword matlabScope		persistent global						| " YD --- added
   syn keyword matlabTryCatch		try catch
   syn keyword matlabExceptions	rethrow throw
end

" --- «end» operators ---
"     ... The Basic (Procedural)  ...
syn match matlabProceduralEnd		'\<end\>' 								" YD 
"     ... Inside an Index Expression ...
syn match matlabIndexEnd		'\%([-+{\*\:(\/\[]\s*\)\@<=\<end\>' 					" YD 
syn match matlabIndexEnd		'\<end\>\%(\s*[-+}\:\*\/)\]]\)\@=' 					" YD 
"     ... As a Function (Operator Overloading) ...
syn match matlabOperatorEnd		'\<end\>\%(\s*(\)\@='

" =========== "Blocks" ===========
" --- Class Blocks ---
"     ... classdef-end blocks ...
syn region matlabClassdefBlock		transparent fold matchgroup=matlabClassdef	start='\%(^\s*\)\@<=classdef\>'	end='\%([-+{\*\:(\/\[]\s*\)\@<!\<end\>\%(\s*[-+}\:\*\/()\]]\)\@!'	contains=ALLBUT,matlabClassdefBlock
"     ... class-end blocks ...
syn region matlabClassBlock		transparent fold matchgroup=matlabClass		start='\<methods\>'		end='\%([-+{\*\:(\/\[]\s*\)\@<!\<end\>\%(\s*[-+}\:\*\/()\]]\)\@!'	contains=ALLBUT,matlabClassdefBlock,matlabClassBlock
syn region matlabClassBlock		transparent fold matchgroup=matlabClass		start='\<properties\>'		end='\%([-+{\*\:(\/\[]\s*\)\@<!\<end\>\%(\s*[-+}\:\*\/()\]]\)\@!'	contains=ALLBUT,@matlabClassCluster,@matlabProceduralCluster
syn region matlabClassBlock		transparent fold matchgroup=matlabClass		start='\<events\>'		end='\%([-+{\*\:(\/\[]\s*\)\@<!\<end\>\%(\s*[-+}\:\*\/()\]]\)\@!'	contains=ALLBUT,@matlabClassCluster,@matlabProceduralCluster
syn region matlabClassBlock		transparent fold matchgroup=matlabClass		start='\<enumeration\>'		end='\%([-+{\*\:(\/\[]\s*\)\@<!\<end\>\%(\s*[-+}\:\*\/()\]]\)\@!'	contains=ALLBUT,@matlabClassCluster,@matlabProceduralCluster

" --- Function Blocks ---
"     ... function-end blocks ...
if s:functionWithoutEndStatement
   syn region matlabFunctionNoEndBlock	transparent fold matchgroup=matlabFunction	start='\%(^\s*\)\@<=function\>'	end='\%(^\s*function\>\)\@='						contains=ALLBUT,@matlabClassCluster
else
   syn region matlabFunctionBlock	transparent fold matchgroup=matlabFunction	start='\<function\>'		end='\%([-+{\*\:(\/\[]\s*\)\@<!\<end\>\%(\s*[-+}\:\*\/()\]]\)\@!'	contains=ALLBUT,matlabClassdefBlock,matlabClassBlock 
end
" TODO - Add function without and «end»
" --- Procedural Blocks ---
"     ... if-end blocks ...
syn region matlabIfBlock		transparent fold matchgroup=matlabIf		start='\<if\>'			end='\%([-+{\*\:(\/\[]\s*\)\@<!\<end\>\%(\s*[-+}\:\*\/()\]]\)\@!'	contains=ALLBUT,@matlabClassCluster
"     ... switch-end blocks ...
syn region matlabSwitchBlock		transparent fold matchgroup=matlabSwitch	start='\<switch\>'		end='\%([-+{\*\:(\/\[]\s*\)\@<!\<end\>\%(\s*[-+}\:\*\/()\]]\)\@!'	contains=ALLBUT,@matlabClassCluster
syn region matlabLabelBlock		transparent fold matchgroup=matlabLabel		start='\<case\>'		end='\%(^\s*\%(case\|otherwise\|end\)\>\)\@='				contains=ALLBUT,@matlabClassCluster containedin=matlabSwitch 
syn region matlabLabelBlock		transparent fold matchgroup=matlabLabel		start='\<otherwise\>'		end='\%(^\s*end\>\)\@='							contains=ALLBUT,@matlabClassCluster containedin=matlabSwitch 
"     ... for/while/parfor-end blocks ...
syn region matlabLoopBlock		transparent fold matchgroup=matlabLoop		start='\<for\>'			end='\%([-+{\*\:(\/\[]\s*\)\@<!\<end\>\%(\s*[-+}\:\*\/()\]]\)\@!'	contains=ALLBUT,@matlabClassCluster
syn region matlabLoopBlock		transparent fold matchgroup=matlabLoop		start='\<parfor\>'		end='\%([-+{\*\:(\/\[]\s*\)\@<!\<end\>\%(\s*[-+}\:\*\/()\]]\)\@!'	contains=ALLBUT,@matlabClassCluster
syn region matlabLoopBlock		transparent fold matchgroup=matlabLoop		start='\<while\>'		end='\%([-+{\*\:(\/\[]\s*\)\@<!\<end\>\%(\s*[-+}\:\*\/()\]]\)\@!'	contains=ALLBUT,@matlabClassCluster
" --- Exception Blocks ---
"     ... try-end blocks ...
syn region matlabTryBlock		transparent fold matchgroup=matlabTry		start='\<try\>'			end='\%([-+{\*\:(\/\[]\s*\)\@<!\<end\>\%(\s*[-+}\:\*\/()\]]\)\@!'	contains=ALLBUT,@matlabClassCluster

" --- Cluster the Blocks ---
syn cluster matlabProceduralCluster	contains=matlabIfBlock,matlabSwitchBlock,matlabLoopBlock,matlabTryBlock,matlabFunctionBlock
syn cluster matlabClassCluster		contains=matlabClassdefBlock,matlabClassBlock,matlabFunctionNoEndBlock,matlabFunctionBlock

"" --- Todo words --- 
syn match matlabTodo			"\c\<\%(todo\|notes\?\|fixme\|xxx\)\%(\s\d\+\|\d*\)\>:\=" 	contained	" YD
"syn keyword matlabTodo			contained	TODO NOTE FIXME XXX
" --- Import ---
syn keyword matlabImport		import
" --- System Command ---
syn match matlabSystemCommand		"!.*"						" YD

" =========== "Operators" ===========
" If you do not want these operators lit, uncommment them and the "hi link" below
" The Errors are inserted just before the operator definition to indicate syntax problems
" --- Relational Operators ---
syn match matlabRelationalOperator	"\%(==\|\~=\|>=\|<=\|=\~\|>\|<\|=\)"	
" --- Arithmetical Operators ---
syn match matlabArithmeticOperator	"[-+]"						
syn match matlabError			"\."						" YD
syn match matlabArithmeticOperator	"\.\=[*/\\^]"					
syn match matlabError			"\%(\.\=[*/\\^]\)\{2,}"				" YD
" --- Logical Operators ---
syn match matlabBoolean			'\<true\>\|\<false\>'
"syn keyword matlabBoolean		true false
syn match matlabLogicalOperator		"[&|~]"
syn match matlabError			"\%(&|\||&\)"					" YD
syn match matlabError			"\%([&|]\)\{3,}"				" YD
" --- Function Handle ---
syn match matlabError			"@"						" YD
syn match matlabFunctionHandle		"@\%(\s*[(A-Za-z]\)\@="				" YD
" --- Meta-Class Operator ---
syn match matlabError			"?"						" YD
syn match matlabQuestionMark		"?\%(\s*[A-Za-z]\)\@="				" YD
" --- Structure Dot ---
syn match matlabStructDot		"\%(\w\|)\|}\)\@<=\.\%(\a\|(\)\@="		" YD
" --- Colon Operator ---
syn match matlabColon			":"						" YD
" --- Line Continuation ---
syn match matlabLineContinuation	"\.\{3}"

" --- Errors ---
" Additional errors that weren't defined above.
"     ... Underscore in Word Start ...
syn match matlabError			'\<_\w*'		" YD
"     ... Word Containing Unused Characters ...
syn match matlabError			'\w*[`#$"]\w*'		" YD

" =========== "Strings" ===========
" --- Basic String ---
syn region matlabString			start=+'+ skip=/\%(''\)\+/ end=+'+	oneline	contains=@Spell,matlabTexFormat,matlabSprintfFormat	" YD
" --- Incomplete String ---
syn match matlabIncompleteString	"'\%([^']\|''\)*"			contains=matlabString,matlabIncompleteString			" YD

" --- Sprinf Formats ---
"     ... Special Chars ...
syn match matlabSprintfFormat		"\\[abfnrtv]"			contained				" YD
syn match matlabSprintfFormat		"\\x[\x\o]\+" 			contained				" YD
syn match matlabSprintfFormat		"\%(%%\|\\\\\)" 		contains=matlabTexFormat contained	" YD
"     ... Input Formats ...
syn match matlabSprintfFormat		"%\%(\d\+\$\)\?[-+ 0#]\?\%(\d\+\|\*\|\*\d\+\$\)\?\%(\.\d\+\|\.\*\|\.\*\d\+\$\)\?\%([cdeEfgGiosuqxX]\|[bt][ouxX]\|[hl][diouxX]\)"	 contained " YD
"syn match matlabSprintfFormat		"%[-+ 0#]\?\%(\d\+\)\?\%(\.\d\+\)\?[cdeEfgGosuxX]" contained	" YD (simple sprintf)

" --- TeX Keywords ---
syn match matlabTexFormat		"\\\%([Aa]lpha\|[Bb]eta\|[Gg]amma\|[Dd]elta\|[Ee]psilon\|[Zz]eta\|[Ee]ta\|[Tt]heta\|[Ii]ota\|[Kk]appa\|[Ll]ambda\)" 			contained " YD
syn match matlabTexFormat		"\\\%([Mm]u\|[Nn]u\|[Xx]i\|[Pp]i\|[Rr]ho\|[Ss]igma\|[Tt]au\|[Uu]psilon\|[Pp]hi\|[Cc]hi\|[Pp]si\|[Oo]mega\)" 				contained " YD
syn match matlabTexFormat		"\\\%(sim\|leq\|infty\|clubsuit\|diamondsuit\|heartsuit\|spadesuit\|leftrightarrow\|vartheta\|leftarrow\|uparrow\|rightarrow\)" 	contained " YD
syn match matlabTexFormat		"\\\%(downarrow\|circ\|pm\|geq\|propto\|forall\|partial\|exists\|bullet\|varsigma\|div\|cong\|neq\|equiv\|approx\|aleph\|Im\)" 		contained " YD
syn match matlabTexFormat		"\\\%(Re\|wp\|otimes\|oplus\|oslash\|cap\|cup\|supseteq\|supset\|subseteq\|subset\|int\|in\|rfloor\|lceil\|nabla\|lfloor\|cdot\)"	contained " YD
syn match matlabTexFormat		"\\\%(ldots\|perp\|neg\|prime\|wedge\|times\|0\|rceil\|surd\|mid\|vee\|varpi\|copyright\|langle\|rangle\)"				contained " YD
syn match matlabTexFormat		"\\\%(rm\|it\|bf\|color\|textfont\|textsize\)"

" --- LaTeX Keywords ---
" TODO: add LaTeX keywords

" --- regexp formats ---
" TODO: add regexp formats

" =========== "Numbers" ===========
" --- Standard numbers ---
syn match matlabNumber		"\<\d\+[ij]\=\>"					
" --- floating point number, ending with a dot, optional exponent ---
syn match matlabFloat		"\<\d\+\."		" YD
" --- floating point number, with dot, optional exponent ---
syn match matlabFloat		"\<\d\+\%(\.\d*\)\=\%([edED][-+]\=\d\+\)\=[ij]\=\>"	
" --- floating point number, starting with a dot, optional exponent ---
syn match matlabFloat		"\.\d\+\%([edED][-+]\=\d\+\)\=[ij]\=\>"			

" =========== "Brackets and Operators" ===========
" Due to Vim's syntax parsing, the definition order is highly important
" --- Delimiters ---
" Either use just [...] or {...} or (...) as well
if s:syntax_block_definitions			" YD
   syn match matlabDelimiterError	"[][]"
   syn match matlabDelimiterError	"[}{]"
   syn match matlabDelimiterError	"[)(]"
   syn region matlabDelimiterBlock	transparent fold matchgroup=matlabDelimiter start="\[" end="\]" contains=ALLBUT,@matlabClassCluster,@matlabProceduralCluster
   syn region matlabDelimiterBlock	transparent fold matchgroup=matlabDelimiter start="("  end=")"  contains=ALLBUT,@matlabClassCluster,@matlabProceduralCluster
   syn region matlabDelimiterBlock	transparent fold matchgroup=matlabDelimiter start="{"  end="}"  contains=ALLBUT,@matlabClassCluster,@matlabProceduralCluster
else
   syn match matlabDelimiter		"[][]"
   syn match matlabDelimiter		"[}{]"	" YD
   syn match matlabDelimiter		"[)(]"	" YD
   "syn match matlabDelimiter		"[][()]"
endif
" --- Transpose Operator ---
syn match matlabTransposeOperator	"[])}a-zA-Z0-9]'\+"lc=1		
syn match matlabTransposeOperator	"[])}a-zA-Z0-9]\.'\+"lc=1	
" --- Terminators ---
syn match matlabComma			","    				display " YD
syn match matlabSemicolon		";"				display " YD

" =========== "Descriptions" ===========
" --- Tabs ---
" Tab definition should appear before matlabTitle; otherwise Vim doesn't recognize it.
syn match matlabTab			"\t"											" If you don't like tabs
" --- Cells ---
syn match matlabTitle			'\%(^\s*\)\@<=%%\%($\|\s.*$\)'	contains=matlabTodo,@Spell				" YD
" TODO - matlabTitleBlock
" --- M-Lint ---
syn match matlabMLint			'%#ok\%(<\*\?\u\+\%(,\u\+\)*>\)\?' contained  						" YD
" --- Comments ---
"     ... Line Continuation ...
syn match matlabLineContinuationComment	'\.\{3}.*$'			contains=matlabLineContinuation,matlabTodo,@Spell	" YD
"     ... Normal Comment ...
syn match matlabComment			"%.*$"				contains=matlabTodo,matlabTitle,matlabMLint,@Spell	" YD
"     ... Block Comment ...
syn region matlabBlockComment		start=+%{+	end=+%}+	contains=matlabBlockComment,@Spell fold			| " YD (fold)
syn region matlabCommentRegion		start=+\%(^\s*\)\@<=%\%(%\s\)\@!+ skip=+^\s*%\%($\|[^%]\|%\S\)+ end=+^+ transparent contains=@Spell,@matlabCommentCluster fold | " YD (fold)
"     ... Comment Cluster ...
syn cluster matlabCommentCluster	contains=matlabComment,matlabMLint,matlabTitle,matlabBlockComment,matlabTodo

" 	########################### "KEYWORDS" ############################
" =========== "Desktop Tools and Development Environment" ===========
" --- Startup and Shutdown ---
syn keyword matlabFunc			exit finish matlab matlabrc prefdir preferences quit startup userpath
" --- Command Window and History ---
syn keyword matlabFunc			clc commandhistory commandwindow diary dos format home more perl system unix
" --- Help for Using MATLAB ---
syn keyword matlabFunc			help builddocsearchdb demo doc docsearch echodemo helpbrowser helpwin info lookfor playshow support web whatsnew
" --- Workspace, Search Path, and File Operations ---
"     ... Workspace ...
syn keyword matlabFunc			assignin clear evalin exist openvar pack uiimport which who whos workspace clearvars
"     ... Search Path ...
syn keyword matlabFunc			addpath genpath path path2rc pathsep pathtool restoredefaultpath rmpath savepath userpath
"     ... File Operations ...
syn keyword matlabFunc			cd copyfile delete dir exist fileattrib filebrowser isdir lookfor ls matlabroot mkdir movefile pwd recycle rehash rmdir 
syn keyword matlabFunc			tempdir toolboxdir type visdiff what which
" --- Programming Tools ---
"     ... M-File Editing and Debugging ...
syn keyword matlabFunc			clipboard datatipinfo dbclear dbcont dbdown dbquit dbstack dbstatus dbstep dbstop dbtype dbup edit keyboard
"     ... M-File Performance ...
syn keyword matlabFunc			bench mlint mlintrpt pack profile profsave rehash
"     ... Source Control ...
syn keyword matlabFunc			checkin checkout cmopts customverctrl undocheckout verctrl
"     ... Publishing ...
syn keyword matlabFunc			grabcode notebook publish snapnow
" --- System ---
"     ... Operating System Interface ...
syn keyword matlabFunc			clipboard computer dos getenv hostid perl setenv system unix winqueryreg
"     ... MATLAB Version and License ...
syn keyword matlabFunc			ismac ispc isstudent isunix javachk license prefdir usejava ver verLessThan version 

" =========== "Data Import and Export" ===========
" --- File Name Construction ---
syn keyword matlabFunc			filemarker fileparts filesep fullfile tempdir tempname
" --- File Opening, Loading, and Saving ---
syn keyword matlabFunc			daqread importdata load open save uiimport winopen
" --- Memory Mapping ---
syn keyword matlabFunc			disp get memmapfile
" --- Low-Level File I/O ---
syn keyword matlabFunc			fclose feof ferror fgetl fgets fopen fprintf fread frewind fscanf fseek ftell fwrite
" --- Text Files ---
syn keyword matlabFunc			csvread csvwrite dlmread dlmwrite fileread textread textscan
" --- XML Documents ---
syn keyword matlabFunc			xmlread xmlwrite xslt
" --- Spreadsheets ---
"     ... Microsoft Excel ...
syn keyword matlabFunc			xlsfinfo xlsread xlswrite
"     ... Lotus 1-2-3 ...
syn keyword matlabFunc			wk1finfo wk1read wk1write
" --- Scientific Data ---
"     ... Common Data Format ...
syn keyword matlabFunc			cdfepoch cdfinfo cdfread cdfwrite todatenum
"     ... Network Common Data Form ...
syn keyword matlabFunc			netcdf 
syn match matlabFunc			'\%(\<netcdf\.\)\@<=\%(abort\|close\|create\|endDef\|getConstant\|getConstantNames\|inq\)\>'
syn match matlabFunc			'\%(\<netcdf\.\)\@<=\%(inqLibVers\|open\|reDef\|setDefaultFormat\|setFill\|sync\|defDim\|inqDim\)\>'
syn match matlabFunc			'\%(\<netcdf\.\)\@<=\%(inqDimID\|renameDim\|defVar\|getVar\|inqVar\|inqVarID\|putVar\|renameVar\)\>'
syn match matlabFunc			'\%(\<netcdf\.\)\@<=\%(copyAtt\|delAtt\|getAtt\|inqAtt\|inqAttID\|inqAttName\|putAtt\|renameAt\)\>'
"     ... Network Common Data Form 2010b ...
syn match matlabFunc			'\%(\<netcdf\.\)\@<=\%(inqFormat\|inqUnlimDims\|defGrp\|inqNcid\|inqGrps\|inqVarIDs\|inqDimIDs\|inqGrpName\)\>'
syn match matlabFunc			'\%(\<netcdf\.\)\@<=\%(inqGrpNameFull\|inqGrpParent\|defVarChunking\|defVarDeflate\|defVarFill\)\>'
syn match matlabFunc			'\%(\<netcdf\.\)\@<=\%(defVarFletcher32\|inqVarChunking\|inqVarDeflate\|inqVarFill\|inqVarFletcher32\)\>'
"     ... Flexible Image Transport System ...
syn keyword matlabFunc			fitsinfo fitsread
"     ... Hierarchical Data Format ...
syn keyword matlabFunc			hdf hdf5 hdf5info hdf5read hdf5write hdfinfo hdfread hdftool
"     ... Band-Interleaved Data ...
syn keyword matlabFunc			multibandread multibandwrite
" --- Audio and Video ---
"     ... Reading and Writing Files ...
syn keyword matlabFunc			addframe aufinfo auread auwrite avifile aviinfo aviread close mmfileinfo mmreader movie2avi 
syn keyword matlabFunc			read wavfinfo wavread wavwrite 
syn match matlabFunc			'\%(\<mmreader\.\)\@<=isPlatformSupported\>'
"     ... Recording and Playback ...
syn keyword matlabFunc			audiodevinfo audioplayer audiorecorder sound soundsc wavplay wavrecord
"     ... Utilities ...
syn keyword matlabFunc			beep lin2mu mu2lin
" --- Images ---
syn keyword matlabFunc			exifread im2java imfinfo imread imwrite Tiff
" --- Internet Exchange ---
"     ... URL, Zip, Tar, E-Mail ...
syn keyword matlabFunc			gunzip gzip sendmail tar untar unzip urlread urlwrite zip
"     ... FTP ...
syn keyword matlabFunc			ascii binary cd close delete dir ftp mget mkdir mput rename rmdir 

" =========== "Mathematics" ===========
" --- Arrays and Matrices ---
"     ... Basic Information ...
syn keyword matlabFunc			disp display isempty isequal isequalwithequalnans isfinite isfloat isinf isinteger islogical isnan isnumeric isscalar 
syn keyword matlabFunc			issparse isvector length max min ndims numel size
"     ... 2010b Basic Information Additions ...
syn keyword matlabFunc			isrow iscolumn ismatrix
"     ... Elementary Matrices and Arrays ...
syn keyword matlabFunc			blkdiag diag eye freqspace ind2sub linspace logspace meshgrid ndgrid ones rand randi randn RandStream sub2ind zeros
"     ... Array Operations ...
syn keyword matlabFunc			accumarray arrayfun bsxfun cast cross cumprod cumsum dot idivide kron prod sum tril triu
"     ... Array Manipulation ...
syn keyword matlabFunc			blkdiag cat circshift diag flipdim fliplr flipud horzcat inline ipermute permute repmat reshape rot90 shiftdim sort 
syn keyword matlabFunc			sortrows squeeze vectorize vertcat
"syn keyword matlabFunc			end
"     ... Specialized Matrices ...
syn keyword matlabFunc			compan gallery hadamard hankel hilb invhilb magic pascal rosser toeplitz vander wilkinson
" --- Linear Algebra ---
"     ... Matrix Analysis ...
syn keyword matlabFunc			cond condeig det norm normest null orth rank rcond rref subspace trace
"     ... Linear Equations ...
syn keyword matlabFunc			chol cholinc cond condest funm ilu inv ldl linsolve lscov lsqnonneg lu luinc pinv qr rcond
"     ... Eigenvalues and Singular Values ...
syn keyword matlabFunc			balance cdf2rdf condeig eig eigs gsvd hess ordeig ordqz ordschur poly polyeig rsf2csf schur sqrtm ss2tf svd svds
"     ... Matrix Logarithms and Exponentials ...
syn keyword matlabFunc			expm logm sqrtm
"     ... Factorization ...
syn keyword matlabFunc			balance cdf2rdf chol cholinc cholupdate gsvd ilu ldl lu luinc planerot qr qrdelete qrinsert qrupdate qz rsf2csf svd
" --- Elementary Math ---
"     ... Trigonometric ...
syn keyword matlabFunc			acos acosd acosh acot acotd acoth acsc acscd acsch asec asecd asech asin asind asinh atan atan2 atand atanh cos cosd cosh 
syn keyword matlabFunc			cot cotd coth csc cscd csch hypot sec secd sech sin sind sinh tan tand tanh
"     ... Exponential ...
syn keyword matlabFunc			exp expm1 log log10 log1p log2 nextpow2 nthroot pow2 reallog realpow realsqrt sqrt
"     ... Complex ...
syn keyword matlabFunc			abs angle complex conj cplxpair i imag isreal j real sign unwrap
"     ... Rounding and Remainder ...
syn keyword matlabFunc			ceil fix floor idivide mod rem round
"     ... Discrete Math ...
syn keyword matlabFunc			factor factorial gcd isprime lcm nchoosek perms primes rat rats
" --- Polynomials ---
syn keyword matlabFunc			conv deconv poly polyder polyeig polyfit polyint polyval polyvalm residue roots
" --- Interpolation and Computational Geometry ---
"     ... Interpolation ... 
syn keyword matlabFunc			dsearch dsearchn griddata griddata3 griddatan interp1 interp1q interp2 interp3 interpft interpn meshgrid mkpp ndgrid 
syn keyword matlabFunc			padecoef pchip ppval spline tsearch tsearchn unmkpp
"     ... Delaunay Triangulation and Tessellation ...
syn keyword matlabFunc			baryToCart cartToBary circumcenters delaunay delaunay3 delaunayn DelaunayTri DelaunayTri edgeAttachments edges faceNormals 
syn keyword matlabFunc			featureEdges freeBoundary incenters inOutStatus isEdge nearestNeighbor neighbors pointLocation size tetramesh trimesh 
syn keyword matlabFunc			triplot TriRep TriRep TriScatteredInterp TriScatteredInterp trisurf vertexAttachments 
"     ... Convex Hull ...
syn keyword matlabFunc			convexHull convhull convhulln patch plot trisurf
"     ... Voronoi Diagrams ...
syn keyword matlabFunc			patch plot voronoi voronoiDiagram voronoin
"     ... Domain Generation ...
syn keyword matlabFunc			meshgrid ndgrid
" --- Cartesian Coordinate System Conversion ---
syn keyword matlabFunc			cart2pol cart2sph pol2cart sph2cart
" --- Nonlinear Numerical Methods ---
"     ... Ordinary Differential Equations ... 
syn keyword matlabFunc			decic deval ode15i ode23 ode45 ode113 ode15s ode23s ode23t ode23tb odefile odeget odeset odextend
"     ... Delay Differential Equations ...
syn keyword matlabFunc			dde23 ddeget ddesd ddeset deval
"     ... Boundary Value Problems ...
syn keyword matlabFunc			bvp4c bvp5c bvpget bvpinit bvpset bvpxtend deval
"     ... Partial Differential Equations ...
syn keyword matlabFunc			pdepe pdeval
"     ... Optimization ...
syn keyword matlabFunc			fminbnd fminsearch fzero lsqnonneg optimget optimset
"     ... Numerical Integration  ...
syn keyword matlabFunc			dblquad quad quad2d quadgk quadl quadv triplequad
" --- Specialized Math ---
syn keyword matlabFunc			airy besselh besseli besselj besselk bessely beta betainc betaincinv betaln ellipj ellipke erf erfc erfcx erfinv erfcinv 
syn keyword matlabFunc			expint gamma gammainc gammaln gammaincinv legendre psi
" --- Sparse Matrices ---
"     ... Elementary Sparse Matrices ... 
syn keyword matlabFunc			spdiags speye sprand sprandn sprandsym
"     ... Full to Sparse Conversion ...
syn keyword matlabFunc			find full sparse spconvert
"     ... Sparse Matrix Manipulation ...
syn keyword matlabFunc			issparse nnz nonzeros nzmax spalloc spfun spones spparms spy
"     ... Reordering Algorithms ...
syn keyword matlabFunc			amd colamd colperm dmperm ldl randperm symamd symrcm
"     ... Linear Algebra ...
syn keyword matlabFunc			cholinc condest eigs ilu luinc normest spaugment sprank svds
"     ... Linear Equations (Iterative Methods) ...
syn keyword matlabFunc			bicg bicgstab bicgstabl cgs gmres lsqr minres pcg qmr symmlq tfqmr
"     ... Tree Operations ...
syn keyword matlabFunc			etree etreeplot gplot symbfact treelayout treeplot unmesh
" --- Math Constants ---
"syn keyword matlabFunc			eps i Inf intmax intmin j NaN pi realmax realmin 

" =========== "Data Analysis" ===========
" --- Basic Operations --- 
syn keyword matlabFunc			brush cumprod cumsum linkdata prod sort sortrows sum
" --- Descriptive Statistics ---
syn keyword matlabFunc			corrcoef cov max mean median min mode std var
" --- Filtering and Convolution ---
syn keyword matlabFunc			conv conv2 convn deconv detrend filter filter2
" --- Interpolation and Regression ---
syn keyword matlabFunc			interp1 interp2 interp3 interpn mldivide mrdivide polyfit polyval
" --- Fourier Transforms ---
syn keyword matlabFunc			abs angle cplxpair fft fft2 fftn fftshift fftw ifft ifft2 ifftn ifftshift nextpow2 unwrap
" --- Derivatives and Integrals ---
syn keyword matlabFunc			cumtrapz del2 diff gradient polyder polyint trapz
" --- Time Series Objects ---
"     ... Utilities ... 
syn keyword matlabFunc			get getdatasamplesize getqualitydesc isempty length plot set size timeseries tsprops tstool tsdata 
syn match matlabFunc			'\%(\<tsdata\.\)\@<=event\>'
"     ... Data Manipulation ...
syn keyword matlabFunc			addsample ctranspose delsample detrend filter getabstime getinterpmethod getsampleusingtime idealfilter resample 
syn keyword matlabFunc			setabstime setinterpmethod synchronize transpose vertcat 
"     ... Event Data ...
syn keyword matlabFunc			addevent delevent gettsafteratevent gettsafterevent gettsatevent gettsbeforeatevent gettsbeforeevent gettsbetweenevents
"     ... Descriptive Statistics ...
syn keyword matlabFunc			iqr max mean median min std sum var 
" --- Time Series Collections ---
"     ... Utilities ... 
syn keyword matlabFunc			get isempty length plot set size tscollection tstool
"     ... Data Manipulation ...
syn keyword matlabFunc			addsampletocollection addts delsamplefromcollection getabstime getsampleusingtime gettimeseriesnames horzcat removets 
syn keyword matlabFunc			resample setabstime settimeseriesnames vertcat 
"     ... 2010b Funcitions ... 
syn keyword matlabFunc			append getsamples 

" =========== "Programming and Data Types" ===========
" --- Data Types --- 
"  " ... Numeric Types ...
syn keyword matlabFunc			arrayfun cast cat class find intmax intmin intwarning ipermute isa isequal isequalwithequalnans isfinite isinf isnan 
syn keyword matlabFunc			isnumeric isreal isscalar isvector permute realmax realmin reshape squeeze zeros
"     ... Characters and Strings ...
syn keyword matlabFunc			cellstr char eval findstr isstr regexp regexpi sprintf sscanf strcat strcmp strcmpi strings strjust strmatch strread 
syn keyword matlabFunc			strrep strtrim strvcat
"     ... Structures ...
syn keyword matlabFunc			arrayfun cell2struct class deal fieldnames getfield isa isequal isfield isscalar isstruct isvector orderfields rmfield 
syn keyword matlabFunc			setfield struct struct2cell structfun
"     ... Cell Arrays ...
syn keyword matlabFunc			cell cell2mat cell2struct celldisp cellfun cellplot cellstr class deal isa iscell iscellstr isequal isscalar isvector 
syn keyword matlabFunc			mat2cell num2cell struct2cell
"     ... Function Handles ...
syn keyword matlabFunc			class feval func2str function_handle functions isa isequal str2func
"     ... Java Classes and Objects ...
syn keyword matlabFunc			cell class clear depfun exist fieldnames im2java import inmem isa isjava javaaddpath javaArray javachk javaclasspath 
syn keyword matlabFunc			javaMethod javaMethodEDT javaObject javaObjectEDT javarmpath methodsview usejava which
"syn keyword matlabFunc			methods 
"     ... Data Type Identification ...
syn keyword matlabFunc			isa iscell iscellstr ischar isfield isfloat ishghandle isinteger isjava islogical isnumeric isobject isreal isstr 
syn keyword matlabFunc			isstruct validateattributes who whos
" --- Data Type Conversion ---
"     ... Numeric ... 
syn keyword matlabFunc			cast double int8 int16 int32 int64 single typecast uint8 uint16 uint32 uint64
"     ... String to Numeric ...
syn keyword matlabFunc			base2dec bin2dec cast hex2dec hex2num str2double str2num unicode2native
"     ... Numeric to String ...
syn keyword matlabFunc			cast char dec2base dec2bin dec2hex int2str mat2str native2unicode num2str
"     ... Other Conversions ...
syn keyword matlabFunc			cell2mat cell2struct datestr func2str logical mat2cell num2cell num2hex str2func str2mat struct2cell
" --- Strings ---
"     ... Description of Strings in MATLAB ... 
syn keyword matlabFunc			strings
"     ... String Creation ...
syn keyword matlabFunc			blanks cellstr char sprintf strcat strvcat
"     ... String Identification ...
syn keyword matlabFunc			isa iscellstr ischar isletter isscalar isspace isstrprop isvector validatestring
"     ... String Manipulation ...
syn keyword matlabFunc			deblank lower strjust strrep strtrim upper
"     ... String Parsing ...
syn keyword matlabFunc			findstr regexp regexpi regexprep regexptranslate sscanf strfind strread strtok
"     ... String Evaluation ...
syn keyword matlabFunc			eval evalc evalin
"     ... String Comparison ...
syn keyword matlabFunc			strcmp strcmpi strmatch strncmp strncmpi
" --- Bit-Wise Operations ---
syn keyword matlabFunc			bitand bitcmp bitget bitmax bitor bitset bitshift bitxor swapbytes
" --- Logical Operations ---
syn keyword matlabFunc			all and any find iskeyword isvarname logical not or xor
"syn keyword matlabFunc			false true 
" --- Relational Operations ---
syn keyword matlabFunc			eq ge gt le lt ne
" --- Set Operations ---
syn keyword matlabFunc			intersect ismember issorted setdiff setxor union unique
" --- Date and Time Operations ---
syn keyword matlabFunc			addtodate calendar clock cputime date datenum datestr datevec eomday etime now weekday
" --- Programming in MATLAB ---
"     ... M-Files and Scripts ... 
syn keyword matlabFunc			addOptional addParamValue addRequired createCopy depdir depfun echo input inputname inputParser 
syn keyword matlabFunc			mfilename namelengthmax nargchk nargin nargout nargoutchk parse pcode script syntax varargin varargout
"syn keyword matlabFunc			end function 
"     ... Evaluation ...
syn keyword matlabFunc			ans arrayfun assert builtin cellfun echo eval evalc evalin feval iskeyword isvarname pause run script structfun 
syn keyword matlabFunc			symvar tic toc
"     ... Timer ...
syn keyword matlabFunc			delete disp get isvalid set start startat stop timer timerfind timerfindall wait
"     ... Variables and Functions in Memory ...
syn keyword matlabFunc			ans assignin datatipinfo genvarname inmem isglobal memory mislocked mlock munlock namelengthmax pack rehash 
"syn keyword matlabFunc			persistent global 
"     ... Control Flow ...
"syn keyword matlabFunc			break case catch continue else elseif error for if otherwise parfor return switch try while
"syn keyword matlabFunc			end
"     ... Error Handling ...
syn keyword matlabFunc			addCause assert disp eq error ferror getReport intwarning isequal last lastwarn MException ne warning
"syn keyword matlabFunc			rethrow throw try catch 
"     ... MEX Programming ...
syn keyword matlabFunc			dbmex inmem mex mexext 
syn match matlabFunc			'\%(\<mex\.\)\@<=.getCompilerConfigurations\>'

" =========== "Object-Oriented Programming" ===========
" --- Classes and Objects --- 
syn keyword matlabFunc			class exist inferiorto isobject loadobj methodsview subsasgn subsindex subsref superiorto
"syn keyword matlabFunc			classdef methods properties 
" --- Handle Classes ---
syn keyword matlabFunc			addlistener addprop delete dynamicprops findobj findprop get getdisp handle hgsetget isvalid notify 
syn keyword matlabFunc			relationaloperators set setdisp 
" --- Events and Listeners ---
syn keyword matlabFunc			addlistener notify event 
"syn keyword matlabFunc			events 
syn match matlabFunc			'\%(\<event\.\)\@<=\%(EventData\|listener\|PropertyEvent\|proplistener\)\>'
" --- Meta-Classes ---
syn keyword matlabFunc			metaclass meta
syn match matlabFunc			'\%(\<meta\.\)\@<=\%(class\|class.fromName\|DynamicProperty\|event\|method\|package\|package.fromName\)\>'
syn match matlabFunc			'\%(\<meta\.\)\@<=\%(getAllPackages\|property\)\>'
" --- Enumerations ---
"syn keyword matlabFunc			enumeration

" =========== "Graphics" ===========
" --- Basic Plots and Graphs --- 
syn keyword matlabFunc			box errorbar hold line loglog plot plot3 plotyy polar semilogx semilogy subplot
" --- Plotting Tools ---
syn keyword matlabFunc			figurepalette pan plotbrowser plotedit plottools propertyeditor rotate3d showplottool zoom
" --- Annotating Plots ---
syn keyword matlabFunc			annotation clabel datacursormode datetick gtext legend rectangle texlabel title xlabel ylabel zlabel
" --- Specialized Plotting ---
"     ... Area, Bar, and Pie Plots ... 
syn keyword matlabFunc			area bar barh bar3 bar3h pareto pie pie3
"     ... Contour Plots ...
syn keyword matlabFunc			contour contour3 contourc contourf ezcontour ezcontourf
"     ... Direction and Velocity Plots ...
syn keyword matlabFunc			comet comet3 compass feather quiver quiver3
"     ... Discrete Data Plots ...
syn keyword matlabFunc			stairs stem stem3
"     ... Function Plots ...
syn keyword matlabFunc			ezcontour ezcontourf ezmesh ezmeshc ezplot ezplot3 ezpolar ezsurf ezsurfc fplot
"     ... Histograms ...
syn keyword matlabFunc			hist histc rose
"     ... Polygons and Surfaces ...
syn keyword matlabFunc			cylinder delaunay delaunay3 delaunayn dsearch ellipsoid fill fill3 inpolygon pcolor polyarea 
syn keyword matlabFunc			rectint ribbon slice sphere waterfall
"     ... Scatter/Bubble Plots ...
syn keyword matlabFunc			plotmatrix scatter scatter3
"     ... Animation ...
syn keyword matlabFunc			frame2im getframe im2frame movie noanimate
" --- Bit-Mapped Images ---
syn keyword matlabFunc			frame2im im2frame im2java image imagesc imfinfo imformats imread imwrite ind2rgb
" --- Printing ---
syn keyword matlabFunc			hgexport orient print printopt printdlg printpreview saveas
" --- Handle Graphics ---
"     ... Graphics Object Identification ... 
syn keyword matlabFunc			allchild ancestor copyobj delete findall findfigs findobj gca gcbf gcbo gco get ishandle propedit set
"     ... Object Creation ...
syn keyword matlabFunc			axes figure hggroup hgtransform image light line patch rectangle root object surface text uicontextmenu
"     ... Plot Objects ...
"     ... Figure Windows ... 
syn keyword matlabFunc			clf close closereq drawnow gcf hgload hgsave newplot opengl refresh saveas
"     ... Axes Operations ...
syn keyword matlabFunc			axis box cla gca grid ishold makehgtform
"     ... Object Property Operations ...
syn keyword matlabFunc			get linkaxes linkprop refreshdata set 

" =========== "3-D Visualization" ===========
" --- Surface and Mesh Plots --- 
"     ... Surface and Mesh Creation ...
syn keyword matlabFunc			hidden mesh meshc meshz peaks surf surfc surface surfl tetramesh trimesh triplot trisurf
"     ... Domain Generation ...
syn keyword matlabFunc			meshgrid 
"     ... Color Operations ... 
syn keyword matlabFunc			brighten caxis colorbar colordef colormap colormapeditor contrast graymon 
syn keyword matlabFunc			hsv2rgb rgb2hsv rgbplot shading spinmap surfnorm whitebg
" --- View Control ---
"     ... Camera Viewpoint ... 
syn keyword matlabFunc			camdolly cameratoolbar camlookat camorbit campan campos camproj camroll camtarget camup camva camzoom 
syn keyword matlabFunc			makehgtform view viewmtx 
"     ... Aspect Ratio and Axis Limits ...  
syn keyword matlabFunc			daspect pbaspect xlim ylim zlim
"     ... Object Manipulation ...
syn keyword matlabFunc			pan reset rotate rotate3d selectmoveresize zoom
"     ... Region of Interest ...
syn keyword matlabFunc			dragrect rbbox
" --- Lighting ---
syn keyword matlabFunc			camlight diffuse light lightangle lighting material specular
" --- Transparency ---
syn keyword matlabFunc			alim alpha alphamap
" --- Volume Visualization ---
syn keyword matlabFunc			coneplot contourslice curl divergence flow interpstreamspeed isocaps isocolors isonormals isosurface reducepatch 
syn keyword matlabFunc			reducevolume shrinkfaces slice smooth3 stream2 stream3 streamline streamparticles streamribbon streamslice 
syn keyword matlabFunc			streamtube subvolume surf2patch volumebounds 

" =========== "GUI Development" ===========
" --- Predefined Dialog Boxes --- 
syn keyword matlabFunc			dialog errordlg export2wsdlg helpdlg inputdlg listdlg msgbox printdlg printpreview questdlg uigetdir uigetfile 
syn keyword matlabFunc			uigetpref uiopen uiputfile uisave uisetcolor uisetfont waitbar warndlg
" --- User Interface Deployment ---
syn keyword matlabFunc			guidata guihandles movegui openfig
" --- User Interface Development ---
syn keyword matlabFunc			addpref getappdata getpref ginput guidata guide inspect isappdata ispref rmappdata rmpref setappdata setpref uigetpref 
syn keyword matlabFunc			uisetpref waitfor waitforbuttonpress
" --- User Interface Objects ---
syn keyword matlabFunc			menu uibuttongroup uicontextmenu uicontrol uimenu uipanel uipushtool uitable uitoggletool uitoolbar
" --- Objects from Callbacks ---
syn keyword matlabFunc			findall findfigs findobj gcbf gcbo
" --- GUI Utilities ---
syn keyword matlabFunc			align getpixelposition listfonts selectmoveresize setpixelposition textwrap uistack
" --- Program Execution ---
syn keyword matlabFunc			uiresume uiwait 
" --- Undocumented Features ---
syn keyword matlabFunc			uiundo uitab uitabgroup

" =========== "External Interfaces" ===========
" --- Shared Libraries --- 
syn keyword matlabFunc			calllib libfunctions libfunctionsview libisloaded libpointer libstruct loadlibrary unloadlibrary
" --- Java ---
syn keyword matlabFunc			class fieldnames import inspect isjava javaaddpath javaArray javachk javaclasspath javaMethod javaMethodEDT javaObject 
syn keyword matlabFunc			javaObjectEDT javarmpath methodsview usejava
"syn keyword matlabFunc			methods 
" --- .NET ---
syn keyword matlabFunc			enableNETfromNetworkDrive NET 
syn match matlabFunc			'\%(\<NET\.\)\@<=\%(addAssembly\|Assembly\|convertArray\|createArray\|createGeneric\|GenericClass\|GenericClass\)\>'
syn match matlabFunc			'\%(\<NET\.\)\@<=\%(invokeGenericMethod\|NetException\|setStaticProperty\)\>'
" --- Component Object Model and ActiveX ---
syn keyword matlabFunc			actxcontrol actxcontrollist actxcontrolselect actxGetRunningServer actxserver addproperty delete deleteproperty 
syn keyword matlabFunc			enableservice eventlisteners Execute Feval fieldnames get GetCharArray GetFullMatrix GetVariable GetWorkspaceData 
syn keyword matlabFunc			inspect interfaces invoke iscom isevent isinterface ismethod isprop load MaximizeCommandWindow methodsview 
syn keyword matlabFunc			MinimizeCommandWindow move propedit   PutCharArray PutFullMatrix PutWorkspaceData Quit registerevent release save set 
syn keyword matlabFunc			unregisterallevents unregisterevent
"syn keyword matlabFunc			events methods
" --- Web Services ---
syn keyword matlabFunc			callSoapService createClassFromWsdl createSoapMessage parseSoapResponse
" --- Serial Port Devices ---
syn keyword matlabFunc			clear delete fgetl fgets fopen fprintf fread fscanf fwrite get instrcallback instrfind instrfindall isvalid length load 
syn keyword matlabFunc			readasync record save serial serialbreak set size stopasync

" =========== "Special Definitions" ===========
" --- Color Operations ---
syn keyword matlabFunc			brighten caxis colorbar colordef colormap colormapeditor contrast graymon hsv2rgb rgb2hsv 
syn keyword matlabFunc			rgbplot shading spinmap surfnorm whitebg
" --- Matlab Colours ---
syn keyword matlabColours		autumn bone colorcube cool copper flag gray hot hsv jet lines pink prism spring summer white winter 
" --- MException Methods ---
syn keyword matlabExceptions		MException throwAsCaller
syn keyword matlabFunc			getReport last addCause
" --- Debugging Programs ---
syn keyword matlabDebug			dbclear dbcont dbdown dbquit dbstack dbstatus dbstep dbstop dbtype dbup
" --- Object-Oriented Arguments ---
"     ... Class arguments
syn keyword matlabClassArgument		Hidden InferiorClasses ConstructOnLoad Sealed
"     ... Properties arguments
syn keyword matlabClassArgument		AbortSet Abstract Access GetAccess SetAccess Constant Dependent Hidden GetObservable SetObservable
"     ... Methods arguments
syn keyword matlabClassArgument		Abstract Access Constant Hidden Sealed Static
"     ... Events arguments
syn keyword matlabClassArgument		Hidden ListenAccess NotifyAccess
"     ... Attributes arguments
syn keyword matlabClassAttribute	public protected private
" --- Data type 
"     ... Numeric
syn keyword matlabType 			double int8 int16 int32 int64 single uint8 uint16 uint32 uint64
syn keyword matlabType 			ones zeros 
"     ... Non-Numeric
syn keyword matlabType 			char struct cell
syn keyword matlabType			inf nan
"     ... Non-Numeric
syn match matlabType 			'\%(\<true\>\|\<false\>\)\%(\s*(\)\@='
"     ... Full to Sparse Conversion
syn keyword matlabFunc			spconvert
syn keyword matlabType			full sparse 
" --- Script M-file description
syn keyword matlabIdentifier		varargin varargout nargin nargout 
" --- Error Handling
syn keyword matlabExceptions		error warning assert 
syn keyword matlabFunc			ferror lasterr lasterror lastwarn 
" --- Math Constants ---
syn keyword matlabConstant		intmax intmin realmax realmin 
syn keyword matlabConstant		eps Inf NaN pi



" 	########################### "LINK HIGHLIGHTS" ############################
" --- Define the Default Highlighting ---
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_matlab_syntax_inits")
   if version < 508
      let did_matlab_syntax_inits = 1
      command -nargs=+ HiLink hi link <args>
   else
      command -nargs=+ HiLink hi def link <args>
   endif


   " --- Link Groups ---
   " For the best view it is recommended to use "matlablight" or "matlabdark" colorschemes.
   " See also "group-name" for help, or Syntax-Highlight-test menu ":runtime syntax/hitest.vim".

   " ... Functions and Statements ...
   HiLink matlabWord			Normal		" YD
   HiLink matlabStatement		Statement
   HiLink matlabFunction		Statement
   "
   HiLink matlabScope			Keyword		" YD
   HiLink matlabImplicit		matlabStatement

   " ... Exceptions ...
   HiLink matlabExceptions		Exception
   if (s:use_exception_try_catch)
      HiLink matlabTryCatch		Exception
      HiLink matlabTry			Exception
   else
      HiLink matlabTryCatch		Statement
      HiLink matlabTry			Statement
   endif

   " ... Labels, Conditionals and Repeats ...
   HiLink matlabConditional		Conditional
   HiLink matlabIf			Conditional
   HiLink matlabSwitch			Conditional
   HiLink matlabLabel			Label
   HiLink matlabRepeat			Repeat
   HiLink matlabLoop			Repeat

   " ... Types, Identifiers and Functions ...
   HiLink matlabType			Type		" YD
   HiLink matlabIdentifier		Identifier	" YD
   HiLink matlabFunc			Function

   " ... Matlab Class ...
   HiLink matlabObjectOriented		Keyword		" YD
   HiLink matlabClassdef		Keyword		" YD
   HiLink matlabClass			Keyword		" YD
   HiLink matlabClassArgument		Identifier	" YD
   HiLink matlabClassAttribute		Boolean		" YD

   " ... End Definitions ...
   HiLink matlabProceduralEnd		Statement
   HiLink matlabIndexEnd		Identifier	" YD
   HiLink matlabOperatorEnd		Function	" YD

   " ... System Commands and PreProc ...
   HiLink matlabSystemCommand		PreProc		" YD
   HiLink matlabImport			Include

   " ... Numbers, Floats and Booleans ...
   HiLink matlabNumber			Number
   HiLink matlabFloat			Float
   HiLink matlabConstant		Constant
   HiLink matlabBoolean			Boolean

   " ... Strings ...
   HiLink matlabString			String
   HiLink matlabIncompleteString	WarningMsg	" YD
   HiLink matlabSprintfFormat		SpecialChar	" YD
   HiLink matlabTexFormat		Character	" YD

   " ... Termination and Line Continuation ...
   HiLink matlabComma			SpecialKey	" YD
   HiLink matlabSemicolon		SpecialKey
   "
   HiLink matlabLineContinuation	Special
   "

   " ... Comments ...
   HiLink matlabTitle			Title		" YD
   "
   HiLink matlabComment			Comment
   HiLink matlabBlockComment		Comment
   HiLink matlabLineContinuationComment	Comment		" YD
   "
   HiLink matlabMLint			SpecialComment	" YD
   "
   HiLink matlabTodo			Todo

   " ... Operators and Delimeters ...
   HiLink matlabDelimiter		Delimiter
   HiLink matlabDelimiterError		Error
   "
   HiLink matlabOperator		Operator
   HiLink matlabStructDot		matlabOperator	" YD
   HiLink matlabColon			matlabOperator	" YD
   HiLink matlabFunctionHandle		matlabOperator	" YD
   HiLink matlabQuestionMark		matlabOperator	" YD
   "
   HiLink matlabArithmeticOperator	matlabOperator
   HiLink matlabRelationalOperator	matlabOperator
   HiLink matlabLogicalOperator		matlabOperator
   HiLink matlabTransposeOperator	matlabOperator

   " ... Miscellaneous ...
   HiLink matlabColours			Identifier	" YD
   HiLink matlabDebug			Debug		" YD
   HiLink matlabError			Error		" YD

   " ... Optional Highlighting ...
   "HiLink matlabTab			Error		" if you don't like Tabs

   delcommand HiLink
endif

let b:current_syntax = "matlab"


"EOF	vim: ts=8 noet tw=100 sw=3 sts=0
