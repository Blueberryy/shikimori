class Users::AchievementsController < ProfilesController
  before_action :additional_breadcrumbs, except: [:index]
  before_action { og page_title: i18n_t('achievements') }
  before_action :check_access

  ACHIEVEMENTS_CLUB_USER_IDS = [
    1,2,9,11,19,22,25,30,35,43,87,94,98,106,143,181,188,192,204,206,210,270,385,392,477,519,525,526,533,539,541,680,717,861,866,883,903,921,932,945,1043,1096,1192,1237,1255,1338,1457,1483,1627,1645,1758,1765,1798,1822,1859,1897,1945,2043,2046,2143,2204,2225,2320,2351,2414,2481,2514,2567,2698,2718,2727,2750,2881,2899,2975,2988,3015,3052,3282,3395,3477,3523,3543,3711,3714,3751,3783,3795,3798,3824,3865,3977,4099,4114,4193,4261,4307,4332,4356,4475,4564,4814,4845,4964,4981,5061,5214,5255,5414,5437,5586,5779,6141,6287,6316,6356,6391,6540,6570,6683,6788,6819,6830,6956,7426,7531,7560,7642,7909,7931,7976,8019,8047,8099,8102,8191,8224,8543,8571,8583,8637,8674,8686,8705,8721,8834,8882,8947,8962,9047,9129,9158,9221,9266,9360,9374,9400,9484,9560,9636,9950,9987,9989,10014,10075,10112,10206,10366,10620,10845,10882,10901,10904,10980,11197,11380,11467,11496,11511,11698,11706,11874,12023,12035,12103,12104,12123,12308,12594,12671,12811,12834,12965,13028,13149,13201,13361,13419,13559,13580,13783,13981,14168,14212,14257,14439,14459,14503,14546,14634,14706,14792,14830,14911,15079,15218,15242,15264,15299,15511,15555,15647,15816,15874,16148,16178,16189,16282,16398,16401,16410,16513,16642,16725,16850,16876,16962,17006,17008,17016,17092,17211,17240,17423,17428,17461,17694,17767,17958,17967,18004,18388,18498,18634,18636,18696,18929,19025,19026,19143,19189,19282,19353,19463,19631,19677,19796,19826,19975,20012,20113,20162,20171,20173,20202,20226,20305,20330,20584,20646,20777,20795,20846,20886,21077,21120,21143,21190,21246,21298,21373,21495,21507,21509,21538,21724,21749,21893,21990,22007,22102,22262,22459,22525,22907,22962,23002,23139,23153,23166,23206,23214,23291,23319,23656,23778,23869,23879,23893,23972,24032,24099,24114,24162,24332,24448,24471,24518,24525,24536,24537,24546,24655,24783,24873,24882,24897,24922,24951,24977,25050,25069,25191,25314,25337,25342,25417,25441,25487,25714,25738,25767,25790,25798,25896,26085,26109,26383,26446,26691,26892,26966,27165,27487,27498,27538,27559,27664,27688,27751,27867,28101,28145,28259,28355,28569,28574,28601,28616,28769,28880,29025,29041,29086,29265,29326,29386,29600,29625,29682,29832,29834,29965,30030,30037,30063,30196,30214,30382,30543,30626,30644,30702,30761,30789,30854,30858,30952,30964,31022,31115,31178,31215,31251,31360,31660,31665,31720,31785,31862,31885,32005,32478,32652,32687,32808,32885,32966,32996,33098,33149,33387,33450,33522,33664,33904,33908,33985,34003,34042,34148,34415,34590,34640,34693,34803,34807,34847,35068,35108,35186,35191,35372,35439,35605,35705,35933,35991,36019,36388,36744,36788,36814,36861,36908,37044,37105,37230,37249,37476,37602,37763,37877,38043,38132,38264,38297,38339,38622,38628,38771,38797,38944,39022,39071,39159,39384,39417,39666,39816,39864,39871,39950,40043,40145,40201,40331,40485,40510,40539,40584,40987,41089,41175,41299,41318,41479,41555,41607,41649,41878,41996,42045,42046,42132,42175,42218,42241,42423,42537,42541,43139,43199,43340,43342,43529,43733,43821,43905,43949,43993,43994,44034,44037,44163,44206,44236,44245,44318,44626,44718,44729,44793,44943,45026,45041,45072,45124,45197,45408,45421,45432,45441,45454,45502,45562,45639,45821,45935,45993,46018,46067,46158,46239,46257,46259,46324,46395,46492,46566,46876,46880,46935,46957,47594,47714,47726,47750,47755,47764,47785,47889,47976,48103,48126,48224,48271,48328,48390,48488,48596,48601,48670,48710,48869,49061,49533,49585,49662,49816,49817,49924,49926,50256,50269,50525,50587,50593,50641,50704,50750,50758,50949,51013,51029,51093,51094,51121,51196,51562,51782,51798,51942,52060,52125,52155,52591,52740,52831,52837,52903,53123,53134,53157,53248,53312,53481,53520,53658,53726,54086,54138,54465,54479,54512,54565,54595,54671,54699,54831,54892,54951,55019,55328,55489,55541,55602,55678,55680,55704,55984,56289,56440,56498,57113,57139,57421,57523,57723,57806,57953,58407,58466,58482,58791,58930,58951,59190,59231,59449,59770,59825,59847,59888,59951,60198,60226,60231,60374,60381,60508,60786,60885,61309,61478,61682,61929,62434,62474,62703,62754,62999,63053,63608,63609,63670,63951,64202,64239,64272,64273,64274,64275,64330,64408,64411,64448,64613,64631,64772,64835,64954,64984,65149,65152,65258,65296,65364,65565,65783,65815,65845,65860,66304,66340,66413,66618,66620,66647,66661,66954,67004,67077,67113,67190,67289,67313,67373,67376,67377,67658,67780,67929,68635,68758,68899,68948,69414,69456,69578,69750,69971,70394,70406,70703,70740,70781,70850,70881,71075,71164,71423,71429,71456,71629,71664,71776,71785,71938,71964,72033,72085,72236,72292,72466,72620,72720,72940,72962,73067,73320,73556,73620,73665,73685,73715,73892,73914,73967,74089,74228,74289,74309,74466,74608,74722,74739,74766,74860,74918,74988,75042,75121,75202,75233,75260,75347,75352,75475,75663,75677,76535,76538,76555,76602,76623,76624,76661,76681,76750,76993,77301,77362,77637,77680,77730,77864,77965,78295,78519,78745,78758,78978,79001,79031,79106,79108,79233,79247,79317,79401,79747,79845,79900,80059,80074,80081,80095,80216,80226,80281,80343,80598,80804,80853,80969,80980,81113,81491,83265,83523,83533,83591,83614,83848,84020,84063,84378,84722,85014,85280,85349,85404,85600,85636,85653,85778,85793,85948,85964,86359,86463,86587,86692,86751,86819,86982,87121,87229,87660,87734,87788,87798,87859,88002,88065,88088,88191,88430,88543,88659,88704,88919,89018,89060,89231,89335,89661,89877,89945,89954,90133,90474,90702,90733,90944,91143,91191,91261,91323,91575,91890,91949,92532,92570,92579,92870,92944,93286,93522,93640,93653,93677,93773,93825,93880,94075,94179,94368,94479,94545,94716,94994,95159,95193,95293,95324,95401,95421,95664,95736,95818,96008,96037,96077,96154,96381,96452,96480,96487,96527,96850,97188,97299,97484,97548,97748,97804,97854,98009,98050,98160,98193,98459,98527,98585,98679,98690,98735,98758,99151,99300,99337,99619,99709,99715,99840,99853,100528,100577,100692,100971,100979,100981,101546,101583,101731,101832,101976,102237,102518,102598,102693,102799,102895,102930,102945,103022,103056,103169,103347,103557,104042,104478,104561,104575,104630,105154,105613,105675,105678,106351,106397,106466,106609,107304,107474,107563,107581,107959,108064,108363,108500,108673,109309,109369,109458,109463,109503,109539,109589,109637,109761,109880,109983,110150,110169,110290,110337,110826,110896,111266,111412,111440,111613,112000,112249,112353,112541,112711,112755,113015,113061,113364,113794,113881,113890,113953,114080,114257,114318,114450,114487,114493,114818,114820,114987,115198,115252,115311,115574,115575,115788,115801,116041,116054,116188,116268,116299,116323,116355,117054,117120,117200,117734,117819,117920,117962,118049,118202,118442,118469,118492,118528,118638,118655,118697,118830,119207,119524,119745,119813,119969,120000,120254,120294,120405,120527,120591,120614,120970,121111,121172,121487,121525,121602,121770,121803,121996,122155,122660,122753,122846,122852,122956,123035,123087,123152,123226,123245,123393,123601,123803,123807,123855,123891,124092,124109,124334,124489,124507,124697,124759,124902,125312,125725,125887,126157,126369,126467,127001,127150,127256,127496,127562,127690,127769,127836,127878,127924,127934,128451,128785,128816,128912,128947,129009,129208,129394,129621,129752,129799,129806,130076,130339,130395,130519,130573,130873,131521,131581,131799,131807,131808,131900,131906,131917,131922,131962,132038,132158,132318,132633,132714,133072,133074,133075,133201,133221,133273,133330,133363,133584,133618,133619,133665,133670,133951,134083,134135,134229,134286,134445,134503,134505,134567,134576,134718,134820,134866,134876,134890,134911,134935,134952,134991,135013,135065,135386,135391,135407,135586,135681,135725,135806,135817,136148,136160,136253,136380,136459,136563,136680,136912,137041,137080,137197,137740,137774,137825,138042,138094,138115,138177,138293,138406,138516,139003,139081,139236,139663,139686,139877,140054,140080,140236,140246,140258,140458,140501,140656,140659,140664,140697,140912,140959,141127,141197,141647,141717,141959,142029,142218,142337,142532,142562,142788,142814,142844,142847,143397,143432,143433,144331,144384,144456,144509,144686,144882,144953,145122,145133,145665,145680,146105,146644,146820,146973,147023,147059,147070,147240,147276,147282,147291,147428,147530,147693,148293,148553,149010,149221,149344,149372,149418,149468,149469,149668,149987,150201,150226,150844,150866,151155,151382,151919,152660,152858,153039,153073,153291,154195,154606,154650,154655,154908,155068,155152,155173,155193,155355,156228,156316,156451,156518,156663,157163,157181,157239,157319,157467,157586,157758,157884,157946,158484,158754,158813,158969,159167,159550,159796,160105,160367,163718,163861,164043,164225,164562,164891,164910,164979,165612,165831,165974,165980,166068,166845,166935,167551,167671,167800,167851,167958,168070,168146,168193,168761,169165,169648,169726,169737,170108,170120,170164,170248,170264,170304,170382,170504,170614,170842,170867,171234,171911,171943,171979,172250,172262,172532,172845,172976,173185,173386,173520,173859,174621,175026,175040,175073,175278,175643,175864,175896,175917,176092,176288,176747,176748,176770,176820,176896,176985,177375,177501,177849,177867,177947,178121,178123,178176,178391,178486,178505,178787,178907,178966,179287,179301,179321,179460,179478,180310,180814,181097,181173,181195,181211,181701,181977,181978,182007,182068,182135,182138,182554,182791,183411,183962,184467,184680,184764,184887,185113,186198,186552,186684,186800,186937,187062,187319,187545,187610,187965,188091,188304,188354,188442,188481,188495,189059,189474,189607,189722,189738,189817,190275,190322,190772,190839,190985,191027,191296,191524,191589,191863,192553,192929,193224,193292,193448,193507,193828,193874,194136,194193,194215,194533,194571,194916,195451,195502,195853,195968,196189,196310,196547,196584,196951,196968,197036,197289,197492,197671,198050,198139,198235,198460,198553,199055,199515,199580,199834,199856,199951,200108,200228,200347,200599,200952,201332,201867,201872,202026,202058,202391,202630,202787,202815,203134,203360,204405,204451,204536,204657,205102,205266,205660,205706,205763,205823,206035,206176,206253,206983,207249,207301,207312,207396,207456,207472,207517,207669,207726,208101,208180,208305,208335,208877,209082,209308,209510,209864,209903,210413,210477,210731,210810,210898,211200,211221,211683,211883,211970,212442,212575,212721,212897,213279,213307,213320,213539,213680,213683,213947,213997,214311,214398,214891,215114,215375,215496,215527,215546,215572,215621,216262,216600,218631,218652,218698,218892,219270,219753,219794,219837,220087,220167,220390,220910,221102,221656,221926,221978,222057,222141,222272,222839,223136,223158,223664,223952,224209,224255,224606,224741,225028,225310,225521,225576,225716,225800,225994,226201,226729,226961,227848,227859,227989,227999,228532,228678,228789,229043,229123,229430,230131,230304,230353,230374,230473,230530,230637,230658,230930,231405,231511,231569,231580,231653,231885,232099,232111,232171,232333,232636,232715,232763,232944,233074,233083,234001,234087,234614,234788,235110,235499,235519,235737,235814,235841,235930,236106,236230,236851,237037,237152,237350,237572,238007,238064,238580,238593,238939,239147,239204,239399,240407,240727,240827,240852,240887,240921,241259,241371,241389,241793,241906,242049,242399,242460,242465,242478,242673,242770,242780,243271,244007,244042,244656,244918,244926,244943,245137,245150,245169,245526,245730,245883,245917,246166,246203,246284,246379,246437,246577,246823,246880,246937,247364,247375,247963,247996,248248,248457,248480,248523,248901,249050,249639,249864,250116,250439,250447,251273,251660,251923,251940,251942,252195,252320,252326,252397,252452,253092,253136,253262,253283,253631,253634,254253,254489,254587,254680,254880,254929,255027,255357,255420,255699,255905,255951,256281,256353,256378,256695,256803,256951,256981,257033,257817,258821,259073,259710,259720,259732,260121,260502,260655,260688,260813,261066,261089,261347,261569,261774,261799,261904,262340,262557,262831,262888,262951,263096,263390,263689,263813,263846,265011,265439,265548,265973,266233,266354,266503,266753,266853,266890,267255,267893,267975,268154,268156,268207,268311,268549,268580,268838,269260,269457,269459,269499,269812,269866,270242,270430,270717,271082,271614,271696,271865,272004,272136,272189,272242,272443,272709,272787,272790,272922,272979,273018,273547,273623,273702,273724,274756,274773,274965,275340,275354,275411,276232,276347,276487,276744,276816,276828,277164,277893,277916,277931,278167,278193,278206,278540,278677,278964,279083,279085,279185,279292,279414,279849,279860,279871,280614,280746,281019,281275,281449,281557,281742,281817,282018,282100,282264,282647,282817,283086,283152,283181,283186,283412,283791,283964,284396,284532,284664,284772,284941,285033,285093,285389,285459,285657,285769,285867,285889,285961,286648,286679,286691,286832,286928,287052,287146,287412,287810,287963,287982,288814,289197,289213,289473,289743,289815,289885,290196,290274,290310,290465,290936,291008,291063,291133,291438,292025,292164,292604,293077,293242,293384,293657,293843,293889,294015,294416,294620,295049,295116,295146,295444,295512,295540,295558,296011,296014,296186,296295,296304,296578,296837,297156,297209,297233,297284,297294,297504,297792,298613,298702,299570,299585,299772,299812,300242,300867,300914,301460,301551,301694,301775,301809,301952,302160,302198,302300,302496,302688,302737,302790,303079,303225,303350,303424,303592,303661,303764,304490,305729,306042,306107,306196,306267,306469,307027,307157,307481,307742,307874,307973,308383,308665,308952,308973,309155,309178,309231,309323,309524,309653,309770,311068,311463,311839,311988,312019,312656,312990,313061,313259,313567,313812,314078,314518,314670,314697,315242,315306,315695,315711,315747,316000,316534,316589,316641,316748,316924,317072,317249,317257,317294,317352,317533,317823,317972,318184,318249,318324,318607,318812,318925,319083,319084,319208,319740,319846,319895,320028,320077,320507,320656,320662,320883,321069,321083,321108,321398,321640,321696,321937,322319,322452,322461,322662,322862,322915,323066,323140,323154,323192,323290,323329,323419,323558,323591,323882,324078,324081,324264,324645,324801,325229,325535,325938,326018,326264,326374,326509,327009,327305,328197,328329,328410,328613,328667,328991,329042,329072,329120,329185,329348,329980,330423,330491,330612,330757,331320,331901,332183,332343,332694,332882,333164,333219,333263,333442,333543,333652,333938,334046,334136,334199,334271,335226,335256,335692,335750,336151,336318,336348,336543,336949,337309,337660,337930,337936,338365,338398,338644,338754,339219,339943,340128,340178,340272,340397,340419,340896,341854,341902,341948,342508,342966,343096,343269,343673,344464,344791,345368,345544,346362,346379,346493,346716,346821,346987,347048,347108,347183,347246,347301,348064,348265,348469,348889,349351,349883,350127,350640,351209,351523,351546,351693,352048,352062,352713,352750,352927,352939,352955,353574,354359,355482,355677,355732,355766,355860,355946,356027,356313,356433,356522,356548,357495,358684,358954,359005,359062,359326,359757,360081,360204,360513,360649,360902,361052,361306,361441,361461,361481,361796,361940,362100,362727,362759,363072,363108,363171,363364,363448,363540,363901,364574,364804,364824,365585,365670,366424,366540,366579,367186,367209,367562,367958,368384,368669,369189,369677,369682,369843,369980,369982,370055,370071,370210,370243,370334,370653,370932,370947,371317,371413,371543,371738,371792,371810,371814,371879,371964,372484,372670,373487,373618,373717,374155,374299,374866,375473,376406,376622,377173,377946,378191,378831,378894,378948,380183,381247,381465,381798,381841,382137,382454,382482,383027,383194,383324,383671,384242,384422,384524,385685,385915,386029,387125,387780,388017,388114,389148,389700,390219,390496,391222,391234,391968,392058,392541,392680,392689,392876,394085,394559,394960,395071,395525,395909,395926,396543,398965,399088,399188,399320,399893,400282,400344,400957,401171,401639,401959,402046,402086,402365,402623,402738,402764,402895,402994,403054,403057,403077,403361,403393,403429,403537,403644,403761,403815,404056,404075,404368,404420,404824,404863,406329,406804,407029,407078,407219,407458,407756,407777,408406,409081,409489,409773,409826,410657,410735,410981,411662,412237,412724,412833,413235,413604,413768,413999,414175,414594,414800,414887,415982,416208,416501,416699,417728,418815,418838,419035,419485,420280,420304,420707,421871,422021,422961,424023,424247,424320,424450,424745,424898,425155,425926,425982,426355,427944,427989,428147,429975,430460,431692,432819,432869,433414,433416,433942,434090,434107,434912,435575,436336,436632,436658,436952,437716,437810,437889,438158,438994,439308,439383,439659,441112,441485,441555,442454,442634,444015,444387,445819,446058,446703,446786,447898,448777,449111,449842,450247,453477,454498,454650,458141,458780
  ]

  def index
    @view = AchievementsView.new(@user)
  end

  def franchise
    og page_title: t('achievements.group.franchise')

    @view = AchievementsView.new(@user)
  end

private

  def check_access
    return if Rails.env.development?
    return if current_user&.admin?
    return if ACHIEVEMENTS_CLUB_USER_IDS.include?(@user.id)

    raise ActiveRecord::RecordNotFound
  end

  def additional_breadcrumbs
    @back_url = profile_achievements_url(@resource)
    breadcrumb i18n_t('achievements'), @back_url
  end
end
