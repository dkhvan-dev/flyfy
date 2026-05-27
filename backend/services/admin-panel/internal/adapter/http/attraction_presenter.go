package http

import (
	"fmt"
	"html/template"
	"net/url"
	"strconv"
	"strings"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
)

const attractionListPageSize = 25

var attractionCategoryNames = map[string]map[string]string{
	"NATURE":        {localeEN: "Nature", localeRU: "Природа"},
	"ARCHITECTURE":  {localeEN: "Architecture", localeRU: "Архитектура"},
	"MUSEUM":        {localeEN: "Museum", localeRU: "Музей"},
	"BEACH":         {localeEN: "Beach", localeRU: "Пляж"},
	"PARK":          {localeEN: "Park", localeRU: "Парк"},
	"TEMPLE":        {localeEN: "Temple", localeRU: "Храм"},
	"ENTERTAINMENT": {localeEN: "Entertainment", localeRU: "Развлечения"},
	"FOOD":          {localeEN: "Food", localeRU: "Еда"},
	"MARKET":        {localeEN: "Market", localeRU: "Рынок"},
	"SHOPPING":      {localeEN: "Shopping", localeRU: "Шопинг"},
	"OTHER":         {localeEN: "Other", localeRU: "Другое"},
	"CULTURE":       {localeEN: "Culture", localeRU: "Культура"},
	"HISTORY":       {localeEN: "History", localeRU: "История"},
	"RELIGION":      {localeEN: "Religion", localeRU: "Религия"},
	"SPORT":         {localeEN: "Sport", localeRU: "Спорт"},
}

var attractionSourceNames = map[string]map[string]string{
	"USER":     {localeEN: "User", localeRU: "Пользователь"},
	"AI_AGENT": {localeEN: "AI agent", localeRU: "AI-агент"},
	"IMPORT":   {localeEN: "Import", localeRU: "Импорт"},
}

var attractionCountryValues = []string{"KZ", "KG", "TJ", "MN", "IS", "IE", "NL", "DK", "FI", "BY", "RS", "GR", "UA", "US", "CA", "SG", "UZ", "RU", "VN", "TH", "PH", "ID", "MV", "SC", "PL", "MX", "BR", "AR", "AB", "CU", "MA", "PT", "IT", "ES", "LU", "DE", "AT", "CH", "SE", "CZ", "FR", "GB", "AU", "NZ", "TZ", "KE", "TR", "AE", "GE", "AZ", "AM", "CN", "KR", "JP", "EG", "MY", "LK", "ME", "IN", "MT", "CY"}

type attractionCityReference struct {
	CountryCode string
	CityID      string
}

var attractionCityValues = []attractionCityReference{
	{CountryCode: "KZ", CityID: "almaty"},
	{CountryCode: "KZ", CityID: "astana"},
	{CountryCode: "KZ", CityID: "shymkent"},
	{CountryCode: "KZ", CityID: "taldykorgan"},
	{CountryCode: "KZ", CityID: "aktau"},
	{CountryCode: "KZ", CityID: "aktobe"},
	{CountryCode: "KZ", CityID: "atyrau"},
	{CountryCode: "KZ", CityID: "balkhash"},
	{CountryCode: "KZ", CityID: "karaganda"},
	{CountryCode: "KZ", CityID: "kokshetau"},
	{CountryCode: "KZ", CityID: "kostanay"},
	{CountryCode: "KZ", CityID: "kyzylorda"},
	{CountryCode: "KZ", CityID: "oral"},
	{CountryCode: "KZ", CityID: "pavlodar"},
	{CountryCode: "KZ", CityID: "petropavlovsk"},
	{CountryCode: "KZ", CityID: "semey"},
	{CountryCode: "KZ", CityID: "taraz"},
	{CountryCode: "KZ", CityID: "turkestan"},
	{CountryCode: "KZ", CityID: "ust-kamenogorsk"},
	{CountryCode: "KZ", CityID: "zhezkazgan"},
	{CountryCode: "US", CityID: "new-york"},
	{CountryCode: "US", CityID: "washington-dc"},
	{CountryCode: "US", CityID: "boston"},
	{CountryCode: "US", CityID: "philadelphia"},
	{CountryCode: "US", CityID: "niagara-falls"},
	{CountryCode: "US", CityID: "chicago"},
	{CountryCode: "US", CityID: "los-angeles"},
	{CountryCode: "US", CityID: "san-francisco"},
	{CountryCode: "US", CityID: "san-diego"},
	{CountryCode: "US", CityID: "las-vegas"},
	{CountryCode: "US", CityID: "seattle"},
	{CountryCode: "US", CityID: "portland"},
	{CountryCode: "US", CityID: "miami"},
	{CountryCode: "US", CityID: "orlando"},
	{CountryCode: "US", CityID: "new-orleans"},
	{CountryCode: "US", CityID: "austin"},
	{CountryCode: "US", CityID: "dallas"},
	{CountryCode: "US", CityID: "houston"},
	{CountryCode: "US", CityID: "san-antonio"},
	{CountryCode: "US", CityID: "grand-canyon"},
	{CountryCode: "US", CityID: "yellowstone"},
	{CountryCode: "US", CityID: "yosemite"},
	{CountryCode: "US", CityID: "zion"},
	{CountryCode: "US", CityID: "rocky-mountain"},
	{CountryCode: "US", CityID: "honolulu"},
	{CountryCode: "US", CityID: "maui"},
	{CountryCode: "US", CityID: "anchorage"},
	{CountryCode: "US", CityID: "denali"},
	{CountryCode: "US", CityID: "nashville"},
	{CountryCode: "US", CityID: "atlanta"},
	{CountryCode: "US", CityID: "charleston"},
	{CountryCode: "US", CityID: "savannah"},
	{CountryCode: "CA", CityID: "toronto"},
	{CountryCode: "CA", CityID: "niagara-falls-ca"},
	{CountryCode: "CA", CityID: "ottawa"},
	{CountryCode: "CA", CityID: "montreal"},
	{CountryCode: "CA", CityID: "quebec-city"},
	{CountryCode: "CA", CityID: "vancouver"},
	{CountryCode: "CA", CityID: "victoria"},
	{CountryCode: "CA", CityID: "whistler"},
	{CountryCode: "CA", CityID: "banff"},
	{CountryCode: "CA", CityID: "jasper"},
	{CountryCode: "CA", CityID: "calgary"},
	{CountryCode: "CA", CityID: "edmonton"},
	{CountryCode: "CA", CityID: "winnipeg"},
	{CountryCode: "CA", CityID: "saskatoon"},
	{CountryCode: "CA", CityID: "regina"},
	{CountryCode: "CA", CityID: "halifax"},
	{CountryCode: "CA", CityID: "charlottetown"},
	{CountryCode: "CA", CityID: "st-johns"},
	{CountryCode: "CA", CityID: "whitehorse"},
	{CountryCode: "CA", CityID: "yellowknife"},
	{CountryCode: "CA", CityID: "churchill"},
	{CountryCode: "SG", CityID: "singapore"},
	{CountryCode: "DK", CityID: "copenhagen"},
	{CountryCode: "DK", CityID: "aarhus"},
	{CountryCode: "DK", CityID: "odense"},
	{CountryCode: "DK", CityID: "aalborg"},
	{CountryCode: "DK", CityID: "billund"},
	{CountryCode: "DK", CityID: "skagen"},
	{CountryCode: "DK", CityID: "ribe"},
	{CountryCode: "DK", CityID: "esbjerg"},
	{CountryCode: "DK", CityID: "roskilde"},
	{CountryCode: "DK", CityID: "helsingor"},
	{CountryCode: "DK", CityID: "hillerod"},
	{CountryCode: "DK", CityID: "mons-klint"},
	{CountryCode: "FI", CityID: "helsinki"},
	{CountryCode: "FI", CityID: "espoo"},
	{CountryCode: "FI", CityID: "vantaa"},
	{CountryCode: "FI", CityID: "turku"},
	{CountryCode: "FI", CityID: "naantali"},
	{CountryCode: "FI", CityID: "tampere"},
	{CountryCode: "FI", CityID: "porvoo"},
	{CountryCode: "FI", CityID: "savonlinna"},
	{CountryCode: "FI", CityID: "kuopio"},
	{CountryCode: "FI", CityID: "jyvaskyla"},
	{CountryCode: "FI", CityID: "lappeenranta"},
	{CountryCode: "FI", CityID: "lahti"},
	{CountryCode: "FI", CityID: "rovaniemi"},
	{CountryCode: "FI", CityID: "levi"},
	{CountryCode: "FI", CityID: "saariselka"},
	{CountryCode: "FI", CityID: "inari"},
	{CountryCode: "FI", CityID: "kilpisjarvi"},
	{CountryCode: "FI", CityID: "oulu"},
	{CountryCode: "KG", CityID: "bishkek"},
	{CountryCode: "KG", CityID: "ala-archa"},
	{CountryCode: "KG", CityID: "tokmok"},
	{CountryCode: "KG", CityID: "chunkurchak"},
	{CountryCode: "KG", CityID: "issyk-ata"},
	{CountryCode: "KG", CityID: "cholpon-ata"},
	{CountryCode: "KG", CityID: "balykchy"},
	{CountryCode: "KG", CityID: "karakol"},
	{CountryCode: "KG", CityID: "jeti-oguz"},
	{CountryCode: "KG", CityID: "barskoon"},
	{CountryCode: "KG", CityID: "skazka-canyon"},
	{CountryCode: "KG", CityID: "bokonbaevo"},
	{CountryCode: "KG", CityID: "tamga"},
	{CountryCode: "KG", CityID: "kaji-say"},
	{CountryCode: "KG", CityID: "naryn"},
	{CountryCode: "KG", CityID: "kochkor"},
	{CountryCode: "KG", CityID: "song-kul"},
	{CountryCode: "KG", CityID: "tash-rabat"},
	{CountryCode: "KG", CityID: "kel-suu"},
	{CountryCode: "KG", CityID: "at-bashy"},
	{CountryCode: "KG", CityID: "osh"},
	{CountryCode: "KG", CityID: "uzgen"},
	{CountryCode: "KG", CityID: "jalal-abad"},
	{CountryCode: "KG", CityID: "arslanbob"},
	{CountryCode: "KG", CityID: "sary-chelek"},
	{CountryCode: "KG", CityID: "talas"},
	{CountryCode: "KG", CityID: "toktogul"},
	{CountryCode: "KG", CityID: "suusamyr"},
	{CountryCode: "TJ", CityID: "dushanbe"},
	{CountryCode: "TJ", CityID: "hisor"},
	{CountryCode: "TJ", CityID: "varzob"},
	{CountryCode: "TJ", CityID: "safed-dara"},
	{CountryCode: "TJ", CityID: "norak"},
	{CountryCode: "TJ", CityID: "khujand"},
	{CountryCode: "TJ", CityID: "guliston-qayraqqum"},
	{CountryCode: "TJ", CityID: "istaravshan"},
	{CountryCode: "TJ", CityID: "panjakent"},
	{CountryCode: "TJ", CityID: "sarazm"},
	{CountryCode: "TJ", CityID: "panjrud"},
	{CountryCode: "TJ", CityID: "seven-lakes"},
	{CountryCode: "TJ", CityID: "fann-mountains"},
	{CountryCode: "TJ", CityID: "kulikalon"},
	{CountryCode: "TJ", CityID: "alauddin"},
	{CountryCode: "TJ", CityID: "iskanderkul"},
	{CountryCode: "TJ", CityID: "khorog"},
	{CountryCode: "TJ", CityID: "garm-chashma"},
	{CountryCode: "TJ", CityID: "jelondy"},
	{CountryCode: "TJ", CityID: "ishkashim"},
	{CountryCode: "TJ", CityID: "wakhan-valley"},
	{CountryCode: "TJ", CityID: "yamchun"},
	{CountryCode: "TJ", CityID: "namadgut"},
	{CountryCode: "TJ", CityID: "vrang"},
	{CountryCode: "TJ", CityID: "langar"},
	{CountryCode: "TJ", CityID: "khargush"},
	{CountryCode: "TJ", CityID: "zorkul"},
	{CountryCode: "TJ", CityID: "bulunkul"},
	{CountryCode: "TJ", CityID: "karakul"},
	{CountryCode: "TJ", CityID: "murghab"},
	{CountryCode: "TJ", CityID: "ak-baital"},
	{CountryCode: "TJ", CityID: "rangkul"},
	{CountryCode: "TJ", CityID: "pamir-highway"},
	{CountryCode: "TJ", CityID: "bokhtar"},
	{CountryCode: "TJ", CityID: "vakhsh"},
	{CountryCode: "TJ", CityID: "vose-hulbuk"},
	{CountryCode: "TJ", CityID: "kulob"},
	{CountryCode: "TJ", CityID: "danghara"},
	{CountryCode: "TJ", CityID: "baljuvon"},
	{CountryCode: "TJ", CityID: "sari-khosor"},
	{CountryCode: "TJ", CityID: "dusti"},
	{CountryCode: "TJ", CityID: "shahrituz"},
	{CountryCode: "TJ", CityID: "nosiri-khusrav"},
	{CountryCode: "TJ", CityID: "qubodiyon"},
	{CountryCode: "TJ", CityID: "muminobod"},
	{CountryCode: "TJ", CityID: "khovaling"},
	{CountryCode: "TJ", CityID: "farkhor"},
	{CountryCode: "MN", CityID: "ulaanbaatar"},
	{CountryCode: "MN", CityID: "gorkhi-terelj"},
	{CountryCode: "MN", CityID: "tsonjin-boldog"},
	{CountryCode: "MN", CityID: "zuunmod"},
	{CountryCode: "MN", CityID: "khustai"},
	{CountryCode: "MN", CityID: "kharkhorin"},
	{CountryCode: "MN", CityID: "orkhon-valley"},
	{CountryCode: "MN", CityID: "tuvkhun"},
	{CountryCode: "MN", CityID: "tsetserleg"},
	{CountryCode: "MN", CityID: "tsenkher"},
	{CountryCode: "MN", CityID: "khorgo-terkhiin-tsagaan-nuur"},
	{CountryCode: "MN", CityID: "murun"},
	{CountryCode: "MN", CityID: "khuvsgul"},
	{CountryCode: "MN", CityID: "khatgal"},
	{CountryCode: "MN", CityID: "amarbayasgalant"},
	{CountryCode: "MN", CityID: "dalanzadgad"},
	{CountryCode: "MN", CityID: "yolyn-am"},
	{CountryCode: "MN", CityID: "khongoryn-els"},
	{CountryCode: "MN", CityID: "bayanzag"},
	{CountryCode: "MN", CityID: "tsagaan-suvarga"},
	{CountryCode: "MN", CityID: "baga-gazriin-chuluu"},
	{CountryCode: "MN", CityID: "sainshand"},
	{CountryCode: "MN", CityID: "khamaryn-khiid"},
	{CountryCode: "MN", CityID: "khermen-tsav"},
	{CountryCode: "MN", CityID: "ulgii"},
	{CountryCode: "MN", CityID: "altai-tavan-bogd"},
	{CountryCode: "MN", CityID: "darkhan"},
	{CountryCode: "MN", CityID: "erdenet"},
	{CountryCode: "MN", CityID: "choibalsan"},
	{CountryCode: "MN", CityID: "khalkh-gol"},
	{CountryCode: "MN", CityID: "binder"},
	{CountryCode: "IS", CityID: "reykjavik"},
	{CountryCode: "IS", CityID: "kopavogur"},
	{CountryCode: "IS", CityID: "seltjarnarnes"},
	{CountryCode: "IS", CityID: "hafnarfjordur"},
	{CountryCode: "IS", CityID: "gardabaer"},
	{CountryCode: "IS", CityID: "mosfellsbaer"},
	{CountryCode: "IS", CityID: "reykjanes"},
	{CountryCode: "IS", CityID: "thingvellir"},
	{CountryCode: "IS", CityID: "geysir"},
	{CountryCode: "IS", CityID: "gullfoss"},
	{CountryCode: "IS", CityID: "selfoss"},
	{CountryCode: "IS", CityID: "hveragerdi"},
	{CountryCode: "IS", CityID: "vik"},
	{CountryCode: "IS", CityID: "skogar"},
	{CountryCode: "IS", CityID: "seljalandsfoss"},
	{CountryCode: "IS", CityID: "jokulsarlon"},
	{CountryCode: "IS", CityID: "skaftafell"},
	{CountryCode: "IS", CityID: "snaefellsnes"},
	{CountryCode: "IS", CityID: "borgarnes"},
	{CountryCode: "IS", CityID: "stykkisholmur"},
	{CountryCode: "IS", CityID: "isafjordur"},
	{CountryCode: "IS", CityID: "latrabjarg"},
	{CountryCode: "IS", CityID: "akureyri"},
	{CountryCode: "IS", CityID: "husavik"},
	{CountryCode: "IS", CityID: "myvatn"},
	{CountryCode: "IS", CityID: "dettifoss"},
	{CountryCode: "IS", CityID: "egilsstadir"},
	{CountryCode: "IS", CityID: "seydisfjordur"},
	{CountryCode: "IS", CityID: "borgarfjordur-eystri"},
	{CountryCode: "IE", CityID: "dublin"},
	{CountryCode: "IE", CityID: "howth"},
	{CountryCode: "IE", CityID: "dun-laoghaire"},
	{CountryCode: "IE", CityID: "bray"},
	{CountryCode: "IE", CityID: "glendalough"},
	{CountryCode: "IE", CityID: "galway"},
	{CountryCode: "IE", CityID: "cliffs-of-moher"},
	{CountryCode: "IE", CityID: "burren"},
	{CountryCode: "IE", CityID: "connemara"},
	{CountryCode: "IE", CityID: "aran-islands"},
	{CountryCode: "IE", CityID: "westport"},
	{CountryCode: "IE", CityID: "achill"},
	{CountryCode: "IE", CityID: "cork"},
	{CountryCode: "IE", CityID: "cobh"},
	{CountryCode: "IE", CityID: "blarney"},
	{CountryCode: "IE", CityID: "kinsale"},
	{CountryCode: "IE", CityID: "killarney"},
	{CountryCode: "IE", CityID: "ring-of-kerry"},
	{CountryCode: "IE", CityID: "dingle"},
	{CountryCode: "IE", CityID: "waterford"},
	{CountryCode: "IE", CityID: "kilkenny"},
	{CountryCode: "IE", CityID: "cashel"},
	{CountryCode: "IE", CityID: "limerick"},
	{CountryCode: "IE", CityID: "sligo"},
	{CountryCode: "IE", CityID: "donegal"},
	{CountryCode: "IE", CityID: "letterkenny"},
	{CountryCode: "IE", CityID: "wexford"},
	{CountryCode: "NL", CityID: "amsterdam"},
	{CountryCode: "NL", CityID: "haarlem"},
	{CountryCode: "NL", CityID: "zaandam"},
	{CountryCode: "NL", CityID: "zaanse-schans"},
	{CountryCode: "NL", CityID: "volendam"},
	{CountryCode: "NL", CityID: "marken"},
	{CountryCode: "NL", CityID: "alkmaar"},
	{CountryCode: "NL", CityID: "zandvoort"},
	{CountryCode: "NL", CityID: "texel"},
	{CountryCode: "NL", CityID: "rotterdam"},
	{CountryCode: "NL", CityID: "the-hague"},
	{CountryCode: "NL", CityID: "scheveningen"},
	{CountryCode: "NL", CityID: "delft"},
	{CountryCode: "NL", CityID: "leiden"},
	{CountryCode: "NL", CityID: "utrecht"},
	{CountryCode: "NL", CityID: "gouda"},
	{CountryCode: "NL", CityID: "kinderdijk"},
	{CountryCode: "NL", CityID: "giethoorn"},
	{CountryCode: "NL", CityID: "groningen"},
	{CountryCode: "NL", CityID: "leeuwarden"},
	{CountryCode: "NL", CityID: "maastricht"},
	{CountryCode: "NL", CityID: "valkenburg"},
	{CountryCode: "NL", CityID: "eindhoven"},
	{CountryCode: "NL", CityID: "den-bosch"},
	{CountryCode: "NL", CityID: "kaatsheuvel"},
	{CountryCode: "NL", CityID: "arnhem"},
	{CountryCode: "NL", CityID: "hoge-veluwe"},
	{CountryCode: "NL", CityID: "nijmegen"},
	{CountryCode: "NL", CityID: "middelburg"},
	{CountryCode: "NL", CityID: "domburg"},
	{CountryCode: "BY", CityID: "minsk"},
	{CountryCode: "BY", CityID: "mir"},
	{CountryCode: "BY", CityID: "nesvizh"},
	{CountryCode: "BY", CityID: "brest"},
	{CountryCode: "BY", CityID: "belovezhskaya-pushcha"},
	{CountryCode: "BY", CityID: "grodno"},
	{CountryCode: "BY", CityID: "lida"},
	{CountryCode: "BY", CityID: "pinsk"},
	{CountryCode: "BY", CityID: "vitebsk"},
	{CountryCode: "BY", CityID: "polotsk"},
	{CountryCode: "BY", CityID: "mogilev"},
	{CountryCode: "BY", CityID: "gomel"},
	{CountryCode: "BY", CityID: "braslav"},
	{CountryCode: "BY", CityID: "naroch"},
	{CountryCode: "BY", CityID: "dudutki"},
	{CountryCode: "BY", CityID: "sula"},
	{CountryCode: "BY", CityID: "silichi"},
	{CountryCode: "BY", CityID: "logoisk"},
	{CountryCode: "BY", CityID: "zaslavl"},
	{CountryCode: "BY", CityID: "khatyn"},
	{CountryCode: "BY", CityID: "stalin-line"},
	{CountryCode: "BY", CityID: "pripyatsky"},
	{CountryCode: "BY", CityID: "turov"},
	{CountryCode: "RS", CityID: "belgrade"},
	{CountryCode: "RS", CityID: "zemun"},
	{CountryCode: "RS", CityID: "avala"},
	{CountryCode: "RS", CityID: "novi-sad"},
	{CountryCode: "RS", CityID: "petrovaradin"},
	{CountryCode: "RS", CityID: "sremski-karlovci"},
	{CountryCode: "RS", CityID: "subotica"},
	{CountryCode: "RS", CityID: "palic"},
	{CountryCode: "RS", CityID: "fruska-gora"},
	{CountryCode: "RS", CityID: "zrenjanin"},
	{CountryCode: "RS", CityID: "nis"},
	{CountryCode: "RS", CityID: "sokobanja"},
	{CountryCode: "RS", CityID: "zajecar"},
	{CountryCode: "RS", CityID: "felix-romuliana"},
	{CountryCode: "RS", CityID: "djerdap"},
	{CountryCode: "RS", CityID: "golubac"},
	{CountryCode: "RS", CityID: "lepenski-vir"},
	{CountryCode: "RS", CityID: "devils-town"},
	{CountryCode: "RS", CityID: "leskovac"},
	{CountryCode: "RS", CityID: "zlatibor"},
	{CountryCode: "RS", CityID: "tara"},
	{CountryCode: "RS", CityID: "mokra-gora"},
	{CountryCode: "RS", CityID: "uvac"},
	{CountryCode: "RS", CityID: "kopaonik"},
	{CountryCode: "RS", CityID: "studenica"},
	{CountryCode: "RS", CityID: "zica"},
	{CountryCode: "RS", CityID: "novi-pazar"},
	{CountryCode: "RS", CityID: "kragujevac"},
	{CountryCode: "RS", CityID: "topola"},
	{CountryCode: "RS", CityID: "cacak"},
	{CountryCode: "RS", CityID: "ovcar-kablar"},
	{CountryCode: "GR", CityID: "athens"},
	{CountryCode: "GR", CityID: "piraeus"},
	{CountryCode: "GR", CityID: "glyfada"},
	{CountryCode: "GR", CityID: "cape-sounion"},
	{CountryCode: "GR", CityID: "thessaloniki"},
	{CountryCode: "GR", CityID: "meteora"},
	{CountryCode: "GR", CityID: "kalambaka"},
	{CountryCode: "GR", CityID: "delphi"},
	{CountryCode: "GR", CityID: "arachova"},
	{CountryCode: "GR", CityID: "olympus"},
	{CountryCode: "GR", CityID: "litochoro"},
	{CountryCode: "GR", CityID: "volos"},
	{CountryCode: "GR", CityID: "pelion"},
	{CountryCode: "GR", CityID: "halkidiki"},
	{CountryCode: "GR", CityID: "santorini"},
	{CountryCode: "GR", CityID: "oia"},
	{CountryCode: "GR", CityID: "fira"},
	{CountryCode: "GR", CityID: "mykonos"},
	{CountryCode: "GR", CityID: "delos"},
	{CountryCode: "GR", CityID: "heraklion"},
	{CountryCode: "GR", CityID: "chania"},
	{CountryCode: "GR", CityID: "rethymno"},
	{CountryCode: "GR", CityID: "agios-nikolaos"},
	{CountryCode: "GR", CityID: "elafonisi"},
	{CountryCode: "GR", CityID: "rhodes"},
	{CountryCode: "GR", CityID: "lindos"},
	{CountryCode: "GR", CityID: "corfu"},
	{CountryCode: "GR", CityID: "paleokastritsa"},
	{CountryCode: "GR", CityID: "zakynthos"},
	{CountryCode: "GR", CityID: "naxos"},
	{CountryCode: "GR", CityID: "paros"},
	{CountryCode: "GR", CityID: "nafplio"},
	{CountryCode: "GR", CityID: "mycenae"},
	{CountryCode: "GR", CityID: "epidaurus"},
	{CountryCode: "GR", CityID: "olympia"},
	{CountryCode: "GR", CityID: "patras"},
	{CountryCode: "GR", CityID: "kalamata"},
	{CountryCode: "GR", CityID: "monemvasia"},
	{CountryCode: "GR", CityID: "mystras"},
	{CountryCode: "GR", CityID: "mani"},
	{CountryCode: "UA", CityID: "kyiv"},
	{CountryCode: "UA", CityID: "lviv"},
	{CountryCode: "UA", CityID: "odesa"},
	{CountryCode: "UA", CityID: "vinnytsia"},
	{CountryCode: "UA", CityID: "cherkasy"},
	{CountryCode: "UA", CityID: "uman"},
	{CountryCode: "UA", CityID: "poltava"},
	{CountryCode: "UA", CityID: "chernivtsi"},
	{CountryCode: "UA", CityID: "ivano-frankivsk"},
	{CountryCode: "UA", CityID: "yaremche"},
	{CountryCode: "UA", CityID: "bukovel"},
	{CountryCode: "UA", CityID: "uzhhorod"},
	{CountryCode: "UA", CityID: "mukachevo"},
	{CountryCode: "UA", CityID: "kamianets-podilskyi"},
	{CountryCode: "UA", CityID: "bilhorod-dnistrovskyi"},
	{CountryCode: "UA", CityID: "shabo"},
	{CountryCode: "UA", CityID: "mykolaiv"},
	{CountryCode: "UA", CityID: "kharkiv"},
	{CountryCode: "UA", CityID: "dnipro"},
	{CountryCode: "UA", CityID: "zaporizhzhia"},
	{CountryCode: "UA", CityID: "sumy"},
	{CountryCode: "UA", CityID: "chernihiv"},
	{CountryCode: "UZ", CityID: "tashkent"},
	{CountryCode: "UZ", CityID: "samarkand"},
	{CountryCode: "UZ", CityID: "bukhara"},
	{CountryCode: "UZ", CityID: "khiva"},
	{CountryCode: "UZ", CityID: "urgench"},
	{CountryCode: "UZ", CityID: "nukus"},
	{CountryCode: "UZ", CityID: "muynak"},
	{CountryCode: "UZ", CityID: "aral-sea"},
	{CountryCode: "UZ", CityID: "fergana"},
	{CountryCode: "UZ", CityID: "margilan"},
	{CountryCode: "UZ", CityID: "kokand"},
	{CountryCode: "UZ", CityID: "rishtan"},
	{CountryCode: "UZ", CityID: "andijan"},
	{CountryCode: "UZ", CityID: "namangan"},
	{CountryCode: "UZ", CityID: "chimgan"},
	{CountryCode: "UZ", CityID: "charvak"},
	{CountryCode: "UZ", CityID: "shahrisabz"},
	{CountryCode: "UZ", CityID: "termez"},
	{CountryCode: "UZ", CityID: "navoi"},
	{CountryCode: "UZ", CityID: "nurata"},
	{CountryCode: "UZ", CityID: "zaamin"},
	{CountryCode: "RU", CityID: "moscow"},
	{CountryCode: "RU", CityID: "saint-petersburg"},
	{CountryCode: "RU", CityID: "kazan"},
	{CountryCode: "RU", CityID: "sochi"},
	{CountryCode: "RU", CityID: "nizhny-novgorod"},
	{CountryCode: "RU", CityID: "yekaterinburg"},
	{CountryCode: "RU", CityID: "vladivostok"},
	{CountryCode: "RU", CityID: "kaliningrad"},
	{CountryCode: "RU", CityID: "volgograd"},
	{CountryCode: "TR", CityID: "istanbul"},
	{CountryCode: "TR", CityID: "princes-islands"},
	{CountryCode: "TR", CityID: "ankara"},
	{CountryCode: "TR", CityID: "antalya"},
	{CountryCode: "TR", CityID: "alanya"},
	{CountryCode: "TR", CityID: "side"},
	{CountryCode: "TR", CityID: "belek"},
	{CountryCode: "TR", CityID: "kemer"},
	{CountryCode: "TR", CityID: "kas"},
	{CountryCode: "TR", CityID: "izmir"},
	{CountryCode: "TR", CityID: "selcuk"},
	{CountryCode: "TR", CityID: "cesme"},
	{CountryCode: "TR", CityID: "bodrum"},
	{CountryCode: "TR", CityID: "marmaris"},
	{CountryCode: "TR", CityID: "fethiye"},
	{CountryCode: "TR", CityID: "oludeniz"},
	{CountryCode: "TR", CityID: "pamukkale"},
	{CountryCode: "TR", CityID: "denizli"},
	{CountryCode: "TR", CityID: "cappadocia"},
	{CountryCode: "TR", CityID: "goreme"},
	{CountryCode: "TR", CityID: "nevsehir"},
	{CountryCode: "TR", CityID: "urgup"},
	{CountryCode: "TR", CityID: "uchisar"},
	{CountryCode: "TR", CityID: "avanos"},
	{CountryCode: "TR", CityID: "konya"},
	{CountryCode: "TR", CityID: "trabzon"},
	{CountryCode: "TR", CityID: "rize"},
	{CountryCode: "TR", CityID: "uzungol"},
	{CountryCode: "TR", CityID: "artvin"},
	{CountryCode: "TR", CityID: "mardin"},
	{CountryCode: "TR", CityID: "sanliurfa"},
	{CountryCode: "TR", CityID: "gaziantep"},
	{CountryCode: "EG", CityID: "cairo"},
	{CountryCode: "EG", CityID: "giza"},
	{CountryCode: "EG", CityID: "alexandria"},
	{CountryCode: "EG", CityID: "north-coast"},
	{CountryCode: "EG", CityID: "port-said"},
	{CountryCode: "EG", CityID: "suez"},
	{CountryCode: "EG", CityID: "ain-sokhna"},
	{CountryCode: "EG", CityID: "luxor"},
	{CountryCode: "EG", CityID: "aswan"},
	{CountryCode: "EG", CityID: "abu-simbel"},
	{CountryCode: "EG", CityID: "hurghada"},
	{CountryCode: "EG", CityID: "el-gouna"},
	{CountryCode: "EG", CityID: "marsa-alam"},
	{CountryCode: "EG", CityID: "sharm-el-sheikh"},
	{CountryCode: "EG", CityID: "dahab"},
	{CountryCode: "EG", CityID: "saint-catherine"},
	{CountryCode: "EG", CityID: "siwa"},
	{CountryCode: "EG", CityID: "fayoum"},
	{CountryCode: "EG", CityID: "bahariya-oasis"},
	{CountryCode: "EG", CityID: "white-desert"},
	{CountryCode: "MY", CityID: "kuala-lumpur"},
	{CountryCode: "MY", CityID: "putrajaya"},
	{CountryCode: "MY", CityID: "selangor"},
	{CountryCode: "MY", CityID: "george-town"},
	{CountryCode: "MY", CityID: "penang"},
	{CountryCode: "MY", CityID: "langkawi"},
	{CountryCode: "MY", CityID: "melaka"},
	{CountryCode: "MY", CityID: "ipoh"},
	{CountryCode: "MY", CityID: "cameron-highlands"},
	{CountryCode: "MY", CityID: "kota-kinabalu"},
	{CountryCode: "MY", CityID: "sandakan"},
	{CountryCode: "MY", CityID: "semporna"},
	{CountryCode: "MY", CityID: "kuching"},
	{CountryCode: "MY", CityID: "miri"},
	{CountryCode: "MY", CityID: "johor-bahru"},
	{CountryCode: "MY", CityID: "desaru"},
	{CountryCode: "MY", CityID: "tioman"},
	{CountryCode: "MY", CityID: "perhentian-islands"},
	{CountryCode: "MY", CityID: "redang"},
	{CountryCode: "MY", CityID: "kuala-terengganu"},
	{CountryCode: "MY", CityID: "kuantan"},
	{CountryCode: "LK", CityID: "colombo"},
	{CountryCode: "LK", CityID: "negombo"},
	{CountryCode: "LK", CityID: "mount-lavinia"},
	{CountryCode: "LK", CityID: "kandy"},
	{CountryCode: "LK", CityID: "sigiriya"},
	{CountryCode: "LK", CityID: "dambulla"},
	{CountryCode: "LK", CityID: "anuradhapura"},
	{CountryCode: "LK", CityID: "polonnaruwa"},
	{CountryCode: "LK", CityID: "galle"},
	{CountryCode: "LK", CityID: "unawatuna"},
	{CountryCode: "LK", CityID: "mirissa"},
	{CountryCode: "LK", CityID: "bentota"},
	{CountryCode: "LK", CityID: "hikkaduwa"},
	{CountryCode: "LK", CityID: "ella"},
	{CountryCode: "LK", CityID: "nuwara-eliya"},
	{CountryCode: "LK", CityID: "haputale"},
	{CountryCode: "LK", CityID: "adams-peak"},
	{CountryCode: "LK", CityID: "yala"},
	{CountryCode: "LK", CityID: "udawalawe"},
	{CountryCode: "LK", CityID: "wilpattu"},
	{CountryCode: "LK", CityID: "trincomalee"},
	{CountryCode: "LK", CityID: "arugam-bay"},
	{CountryCode: "LK", CityID: "jaffna"},
	{CountryCode: "AE", CityID: "dubai"},
	{CountryCode: "AE", CityID: "abu-dhabi"},
	{CountryCode: "AE", CityID: "al-ain"},
	{CountryCode: "AE", CityID: "sharjah"},
	{CountryCode: "AE", CityID: "ajman"},
	{CountryCode: "AE", CityID: "ras-al-khaimah"},
	{CountryCode: "AE", CityID: "fujairah"},
	{CountryCode: "AE", CityID: "umm-al-quwain"},
	{CountryCode: "AE", CityID: "hatta"},
	{CountryCode: "AE", CityID: "khor-fakkan"},
	{CountryCode: "VN", CityID: "hanoi"},
	{CountryCode: "VN", CityID: "ha-long"},
	{CountryCode: "VN", CityID: "ninh-binh"},
	{CountryCode: "VN", CityID: "hue"},
	{CountryCode: "VN", CityID: "da-nang"},
	{CountryCode: "VN", CityID: "hoi-an"},
	{CountryCode: "VN", CityID: "ho-chi-minh-city"},
	{CountryCode: "VN", CityID: "nha-trang"},
	{CountryCode: "VN", CityID: "phu-quoc"},
	{CountryCode: "VN", CityID: "sa-pa"},
	{CountryCode: "VN", CityID: "can-tho"},
	{CountryCode: "VN", CityID: "da-lat"},
	{CountryCode: "VN", CityID: "phan-thiet"},
	{CountryCode: "VN", CityID: "vung-tau"},
	{CountryCode: "VN", CityID: "cat-ba"},
	{CountryCode: "VN", CityID: "ha-giang"},
	{CountryCode: "VN", CityID: "phong-nha"},
	{CountryCode: "TH", CityID: "bangkok"},
	{CountryCode: "TH", CityID: "ayutthaya"},
	{CountryCode: "TH", CityID: "pattaya"},
	{CountryCode: "TH", CityID: "phuket"},
	{CountryCode: "TH", CityID: "krabi"},
	{CountryCode: "TH", CityID: "phang-nga"},
	{CountryCode: "TH", CityID: "chiang-mai"},
	{CountryCode: "TH", CityID: "chiang-rai"},
	{CountryCode: "TH", CityID: "pai"},
	{CountryCode: "TH", CityID: "koh-samui"},
	{CountryCode: "TH", CityID: "koh-phangan"},
	{CountryCode: "TH", CityID: "koh-tao"},
	{CountryCode: "TH", CityID: "hua-hin"},
	{CountryCode: "PH", CityID: "manila"},
	{CountryCode: "PH", CityID: "makati"},
	{CountryCode: "PH", CityID: "taguig"},
	{CountryCode: "PH", CityID: "tagaytay"},
	{CountryCode: "PH", CityID: "cebu-city"},
	{CountryCode: "PH", CityID: "mactan"},
	{CountryCode: "PH", CityID: "bohol"},
	{CountryCode: "PH", CityID: "boracay"},
	{CountryCode: "PH", CityID: "iloilo"},
	{CountryCode: "PH", CityID: "bacolod"},
	{CountryCode: "PH", CityID: "puerto-princesa"},
	{CountryCode: "PH", CityID: "el-nido"},
	{CountryCode: "PH", CityID: "coron"},
	{CountryCode: "PH", CityID: "davao"},
	{CountryCode: "PH", CityID: "siargao"},
	{CountryCode: "PH", CityID: "cagayan-de-oro"},
	{CountryCode: "PH", CityID: "camiguin"},
	{CountryCode: "PH", CityID: "baguio"},
	{CountryCode: "PH", CityID: "vigan"},
	{CountryCode: "PH", CityID: "banaue"},
	{CountryCode: "PH", CityID: "sagada"},
	{CountryCode: "PH", CityID: "la-union"},
	{CountryCode: "PH", CityID: "pagudpud"},
	{CountryCode: "ID", CityID: "denpasar"},
	{CountryCode: "ID", CityID: "kuta"},
	{CountryCode: "ID", CityID: "legian"},
	{CountryCode: "ID", CityID: "seminyak"},
	{CountryCode: "ID", CityID: "canggu"},
	{CountryCode: "ID", CityID: "sanur"},
	{CountryCode: "ID", CityID: "nusa-dua"},
	{CountryCode: "ID", CityID: "jimbaran"},
	{CountryCode: "ID", CityID: "uluwatu"},
	{CountryCode: "ID", CityID: "ubud"},
	{CountryCode: "ID", CityID: "gianyar"},
	{CountryCode: "ID", CityID: "sukawati"},
	{CountryCode: "ID", CityID: "tegallalang"},
	{CountryCode: "ID", CityID: "tampaksiring"},
	{CountryCode: "ID", CityID: "bedugul"},
	{CountryCode: "ID", CityID: "tabanan"},
	{CountryCode: "ID", CityID: "jatiluwih"},
	{CountryCode: "ID", CityID: "lovina"},
	{CountryCode: "ID", CityID: "singaraja"},
	{CountryCode: "ID", CityID: "munduk"},
	{CountryCode: "ID", CityID: "amed"},
	{CountryCode: "ID", CityID: "candidasa"},
	{CountryCode: "ID", CityID: "sidemen"},
	{CountryCode: "ID", CityID: "karangasem"},
	{CountryCode: "ID", CityID: "kintamani"},
	{CountryCode: "ID", CityID: "gilimanuk"},
	{CountryCode: "ID", CityID: "nusa-penida"},
	{CountryCode: "ID", CityID: "nusa-lembongan"},
	{CountryCode: "MV", CityID: "male"},
	{CountryCode: "MV", CityID: "hulhumale"},
	{CountryCode: "MV", CityID: "villingili"},
	{CountryCode: "MV", CityID: "maafushi"},
	{CountryCode: "MV", CityID: "gulhi"},
	{CountryCode: "MV", CityID: "guraidhoo"},
	{CountryCode: "MV", CityID: "dhiffushi"},
	{CountryCode: "MV", CityID: "thulusdhoo"},
	{CountryCode: "MV", CityID: "himmafushi"},
	{CountryCode: "MV", CityID: "huraa"},
	{CountryCode: "MV", CityID: "fulidhoo"},
	{CountryCode: "MV", CityID: "vaadhoo"},
	{CountryCode: "MV", CityID: "rasdhoo"},
	{CountryCode: "MV", CityID: "ukulhas"},
	{CountryCode: "MV", CityID: "dhigurah"},
	{CountryCode: "MV", CityID: "maamigili"},
	{CountryCode: "MV", CityID: "dharavandhoo"},
	{CountryCode: "MV", CityID: "baa-atoll"},
	{CountryCode: "MV", CityID: "addu-city"},
	{CountryCode: "MV", CityID: "fuvahmulah"},
	{CountryCode: "MV", CityID: "gan"},
	{CountryCode: "MV", CityID: "utheemu"},
	{CountryCode: "MV", CityID: "isdhoo"},
	{CountryCode: "MV", CityID: "lhaviyani-atoll"},
	{CountryCode: "GE", CityID: "tbilisi"},
	{CountryCode: "GE", CityID: "mtskheta"},
	{CountryCode: "GE", CityID: "batumi"},
	{CountryCode: "GE", CityID: "kobuleti"},
	{CountryCode: "GE", CityID: "mtsvane-kontskhi"},
	{CountryCode: "GE", CityID: "kvariati"},
	{CountryCode: "GE", CityID: "sarpi"},
	{CountryCode: "GE", CityID: "gonio"},
	{CountryCode: "GE", CityID: "tsikhisdziri"},
	{CountryCode: "GE", CityID: "chakvistavi"},
	{CountryCode: "GE", CityID: "keda"},
	{CountryCode: "GE", CityID: "mirveti"},
	{CountryCode: "GE", CityID: "shekvetili"},
	{CountryCode: "GE", CityID: "kutaisi"},
	{CountryCode: "GE", CityID: "tskaltubo"},
	{CountryCode: "GE", CityID: "martvili"},
	{CountryCode: "GE", CityID: "khoni"},
	{CountryCode: "GE", CityID: "terjola"},
	{CountryCode: "GE", CityID: "vani"},
	{CountryCode: "GE", CityID: "chiatura"},
	{CountryCode: "GE", CityID: "baghdati"},
	{CountryCode: "GE", CityID: "stepantsminda"},
	{CountryCode: "GE", CityID: "gudauri"},
	{CountryCode: "GE", CityID: "telavi"},
	{CountryCode: "GE", CityID: "sighnaghi"},
	{CountryCode: "GE", CityID: "kvareli"},
	{CountryCode: "GE", CityID: "borjomi"},
	{CountryCode: "GE", CityID: "bakuriani"},
	{CountryCode: "GE", CityID: "gori"},
	{CountryCode: "GE", CityID: "uplistsikhe"},
	{CountryCode: "GE", CityID: "vardzia"},
	{CountryCode: "GE", CityID: "aspindza"},
	{CountryCode: "GE", CityID: "mestia"},
	{CountryCode: "GE", CityID: "ushguli"},
	{CountryCode: "AZ", CityID: "baku"},
	{CountryCode: "AZ", CityID: "absheron"},
	{CountryCode: "AZ", CityID: "gobustan"},
	{CountryCode: "AZ", CityID: "mud-volcanoes"},
	{CountryCode: "AZ", CityID: "shamakhi"},
	{CountryCode: "AZ", CityID: "lahij"},
	{CountryCode: "AZ", CityID: "quba"},
	{CountryCode: "AZ", CityID: "qusar"},
	{CountryCode: "AZ", CityID: "shahdag"},
	{CountryCode: "AZ", CityID: "khinalig"},
	{CountryCode: "AZ", CityID: "gabala"},
	{CountryCode: "AZ", CityID: "sheki"},
	{CountryCode: "AZ", CityID: "ganja"},
	{CountryCode: "AZ", CityID: "goygol"},
	{CountryCode: "AZ", CityID: "naftalan"},
	{CountryCode: "AZ", CityID: "mingachevir"},
	{CountryCode: "AZ", CityID: "lankaran"},
	{CountryCode: "AZ", CityID: "astara"},
	{CountryCode: "AZ", CityID: "masalli"},
	{CountryCode: "AZ", CityID: "lerik"},
	{CountryCode: "AZ", CityID: "hirkan"},
	{CountryCode: "AZ", CityID: "gizil-agaj"},
	{CountryCode: "AZ", CityID: "nakhchivan"},
	{CountryCode: "AZ", CityID: "ordubad"},
	{CountryCode: "AZ", CityID: "julfa"},
	{CountryCode: "AZ", CityID: "batabat"},
	{CountryCode: "AM", CityID: "yerevan"},
	{CountryCode: "AM", CityID: "vagharshapat"},
	{CountryCode: "AM", CityID: "garni"},
	{CountryCode: "AM", CityID: "geghard"},
	{CountryCode: "AM", CityID: "byurakan"},
	{CountryCode: "AM", CityID: "ashtarak"},
	{CountryCode: "AM", CityID: "sevan"},
	{CountryCode: "AM", CityID: "shorzha"},
	{CountryCode: "AM", CityID: "gavar"},
	{CountryCode: "AM", CityID: "noratus"},
	{CountryCode: "AM", CityID: "artanish"},
	{CountryCode: "AM", CityID: "dilijan"},
	{CountryCode: "AM", CityID: "gosh"},
	{CountryCode: "AM", CityID: "haghartsin"},
	{CountryCode: "AM", CityID: "ijevan"},
	{CountryCode: "AM", CityID: "yenokavan"},
	{CountryCode: "AM", CityID: "tsaghkadzor"},
	{CountryCode: "AM", CityID: "gyumri"},
	{CountryCode: "AM", CityID: "vanadzor"},
	{CountryCode: "AM", CityID: "alaverdi"},
	{CountryCode: "AM", CityID: "odzun"},
	{CountryCode: "AM", CityID: "stepanavan"},
	{CountryCode: "AM", CityID: "areni"},
	{CountryCode: "AM", CityID: "jermuk"},
	{CountryCode: "AM", CityID: "goris"},
	{CountryCode: "AM", CityID: "tatev"},
	{CountryCode: "AM", CityID: "khndzoresk"},
	{CountryCode: "AM", CityID: "kapan"},
	{CountryCode: "AM", CityID: "meghri"},
	{CountryCode: "CN", CityID: "beijing"},
	{CountryCode: "CN", CityID: "shanghai"},
	{CountryCode: "CN", CityID: "tianjin"},
	{CountryCode: "CN", CityID: "chengde"},
	{CountryCode: "CN", CityID: "qinhuangdao"},
	{CountryCode: "CN", CityID: "datong"},
	{CountryCode: "CN", CityID: "xinzhou"},
	{CountryCode: "CN", CityID: "guangzhou"},
	{CountryCode: "CN", CityID: "shenzhen"},
	{CountryCode: "CN", CityID: "hangzhou"},
	{CountryCode: "CN", CityID: "suzhou"},
	{CountryCode: "CN", CityID: "nanjing"},
	{CountryCode: "CN", CityID: "xian"},
	{CountryCode: "CN", CityID: "chengdu"},
	{CountryCode: "CN", CityID: "chongqing"},
	{CountryCode: "CN", CityID: "haikou"},
	{CountryCode: "CN", CityID: "sanya"},
	{CountryCode: "CN", CityID: "wanning"},
	{CountryCode: "CN", CityID: "lingshui"},
	{CountryCode: "CN", CityID: "qionghai"},
	{CountryCode: "CN", CityID: "danzhou"},
	{CountryCode: "CN", CityID: "wenchang"},
	{CountryCode: "CN", CityID: "xiamen"},
	{CountryCode: "CN", CityID: "qingdao"},
	{CountryCode: "CN", CityID: "guilin"},
	{CountryCode: "CN", CityID: "yangshuo"},
	{CountryCode: "CN", CityID: "zhangjiajie"},
	{CountryCode: "CN", CityID: "huangshan"},
	{CountryCode: "CN", CityID: "lijiang"},
	{CountryCode: "CN", CityID: "dali"},
	{CountryCode: "CN", CityID: "kunming"},
	{CountryCode: "CN", CityID: "luoyang"},
	{CountryCode: "CN", CityID: "dengfeng"},
	{CountryCode: "KR", CityID: "seoul"},
	{CountryCode: "KR", CityID: "incheon"},
	{CountryCode: "KR", CityID: "suwon"},
	{CountryCode: "KR", CityID: "yongin"},
	{CountryCode: "KR", CityID: "paju"},
	{CountryCode: "KR", CityID: "gwacheon"},
	{CountryCode: "KR", CityID: "gapyeong"},
	{CountryCode: "KR", CityID: "busan"},
	{CountryCode: "KR", CityID: "gyeongju"},
	{CountryCode: "KR", CityID: "daegu"},
	{CountryCode: "KR", CityID: "jeju"},
	{CountryCode: "KR", CityID: "seogwipo"},
	{CountryCode: "KR", CityID: "sokcho"},
	{CountryCode: "KR", CityID: "yangyang"},
	{CountryCode: "KR", CityID: "gangneung"},
	{CountryCode: "KR", CityID: "chuncheon"},
	{CountryCode: "KR", CityID: "pyeongchang"},
	{CountryCode: "KR", CityID: "goseong"},
	{CountryCode: "KR", CityID: "cheorwon"},
	{CountryCode: "JP", CityID: "tokyo"},
	{CountryCode: "JP", CityID: "yokohama"},
	{CountryCode: "JP", CityID: "kamakura"},
	{CountryCode: "JP", CityID: "nikko"},
	{CountryCode: "JP", CityID: "hakone"},
	{CountryCode: "JP", CityID: "fujikawaguchiko"},
	{CountryCode: "JP", CityID: "fujiyoshida"},
	{CountryCode: "JP", CityID: "oshino"},
	{CountryCode: "JP", CityID: "gotemba"},
	{CountryCode: "JP", CityID: "osaka"},
	{CountryCode: "JP", CityID: "kyoto"},
	{CountryCode: "JP", CityID: "nara"},
	{CountryCode: "JP", CityID: "kobe"},
	{CountryCode: "JP", CityID: "himeji"},
	{CountryCode: "JP", CityID: "wakayama"},
	{CountryCode: "JP", CityID: "nagoya"},
	{CountryCode: "JP", CityID: "nagakute"},
	{CountryCode: "JP", CityID: "kanazawa"},
	{CountryCode: "JP", CityID: "takayama"},
	{CountryCode: "JP", CityID: "shirakawa-go"},
	{CountryCode: "JP", CityID: "matsumoto"},
	{CountryCode: "JP", CityID: "azumino"},
	{CountryCode: "JP", CityID: "kamikochi"},
	{CountryCode: "JP", CityID: "shizuoka"},
	{CountryCode: "JP", CityID: "shimizu"},
	{CountryCode: "JP", CityID: "sapporo"},
	{CountryCode: "JP", CityID: "otaru"},
	{CountryCode: "JP", CityID: "hakodate"},
	{CountryCode: "JP", CityID: "furano"},
	{CountryCode: "JP", CityID: "biei"},
	{CountryCode: "JP", CityID: "asahikawa"},
	{CountryCode: "JP", CityID: "sendai"},
	{CountryCode: "JP", CityID: "matsushima"},
	{CountryCode: "JP", CityID: "aomori"},
	{CountryCode: "JP", CityID: "akita"},
	{CountryCode: "JP", CityID: "kakunodate"},
	{CountryCode: "JP", CityID: "yamagata"},
	{CountryCode: "JP", CityID: "ginzan-onsen"},
	{CountryCode: "JP", CityID: "zao-onsen"},
	{CountryCode: "JP", CityID: "fukuoka"},
	{CountryCode: "JP", CityID: "hiroshima"},
	{CountryCode: "JP", CityID: "hatsukaichi"},
	{CountryCode: "JP", CityID: "nagasaki"},
	{CountryCode: "JP", CityID: "sasebo"},
	{CountryCode: "JP", CityID: "kumamoto"},
	{CountryCode: "JP", CityID: "beppu"},
	{CountryCode: "JP", CityID: "kagoshima"},
	{CountryCode: "JP", CityID: "naha"},
	{CountryCode: "JP", CityID: "onna"},
	{CountryCode: "JP", CityID: "motobu"},
	{CountryCode: "JP", CityID: "chatan"},
	{CountryCode: "JP", CityID: "ishigaki"},
	{CountryCode: "JP", CityID: "takamatsu"},
	{CountryCode: "JP", CityID: "matsuyama"},
	{CountryCode: "ME", CityID: "podgorica"},
	{CountryCode: "ME", CityID: "cetinje"},
	{CountryCode: "ME", CityID: "lovcen"},
	{CountryCode: "ME", CityID: "virpazar"},
	{CountryCode: "ME", CityID: "ostrog"},
	{CountryCode: "ME", CityID: "niksic"},
	{CountryCode: "ME", CityID: "kotor"},
	{CountryCode: "ME", CityID: "perast"},
	{CountryCode: "ME", CityID: "tivat"},
	{CountryCode: "ME", CityID: "herceg-novi"},
	{CountryCode: "ME", CityID: "risan"},
	{CountryCode: "ME", CityID: "budva"},
	{CountryCode: "ME", CityID: "becici"},
	{CountryCode: "ME", CityID: "sveti-stefan"},
	{CountryCode: "ME", CityID: "petrovac"},
	{CountryCode: "ME", CityID: "bar"},
	{CountryCode: "ME", CityID: "ulcinj"},
	{CountryCode: "ME", CityID: "ada-bojana"},
	{CountryCode: "ME", CityID: "zabljak"},
	{CountryCode: "ME", CityID: "durmitor"},
	{CountryCode: "ME", CityID: "kolasin"},
	{CountryCode: "ME", CityID: "biogradska-gora"},
	{CountryCode: "ME", CityID: "plav"},
	{CountryCode: "ME", CityID: "gusinje"},
	{CountryCode: "IN", CityID: "delhi"},
	{CountryCode: "IN", CityID: "agra"},
	{CountryCode: "IN", CityID: "jaipur"},
	{CountryCode: "IN", CityID: "varanasi"},
	{CountryCode: "IN", CityID: "amritsar"},
	{CountryCode: "IN", CityID: "mumbai"},
	{CountryCode: "IN", CityID: "goa"},
	{CountryCode: "IN", CityID: "udaipur"},
	{CountryCode: "IN", CityID: "jodhpur"},
	{CountryCode: "IN", CityID: "ahmedabad"},
	{CountryCode: "IN", CityID: "pune"},
	{CountryCode: "IN", CityID: "bengaluru"},
	{CountryCode: "IN", CityID: "chennai"},
	{CountryCode: "IN", CityID: "kochi"},
	{CountryCode: "IN", CityID: "mysuru"},
	{CountryCode: "IN", CityID: "hyderabad"},
	{CountryCode: "IN", CityID: "hampi"},
	{CountryCode: "IN", CityID: "munnar"},
	{CountryCode: "IN", CityID: "alappuzha"},
	{CountryCode: "IN", CityID: "kovalam"},
	{CountryCode: "IN", CityID: "kolkata"},
	{CountryCode: "IN", CityID: "darjeeling"},
	{CountryCode: "IN", CityID: "shillong"},
	{CountryCode: "IN", CityID: "guwahati"},
	{CountryCode: "IN", CityID: "gangtok"},
	{CountryCode: "IN", CityID: "rishikesh"},
	{CountryCode: "IN", CityID: "haridwar"},
	{CountryCode: "IN", CityID: "manali"},
	{CountryCode: "IN", CityID: "leh"},
	{CountryCode: "MT", CityID: "valletta"},
	{CountryCode: "MT", CityID: "sliema"},
	{CountryCode: "MT", CityID: "st-julians"},
	{CountryCode: "MT", CityID: "birgu"},
	{CountryCode: "MT", CityID: "mdina"},
	{CountryCode: "MT", CityID: "rabat-malta"},
	{CountryCode: "MT", CityID: "mosta"},
	{CountryCode: "MT", CityID: "dingli"},
	{CountryCode: "MT", CityID: "attard"},
	{CountryCode: "MT", CityID: "ta-qali"},
	{CountryCode: "MT", CityID: "mellieha"},
	{CountryCode: "MT", CityID: "st-pauls-bay"},
	{CountryCode: "MT", CityID: "marsaxlokk"},
	{CountryCode: "MT", CityID: "birzebbuga"},
	{CountryCode: "MT", CityID: "qrendi"},
	{CountryCode: "MT", CityID: "paola"},
	{CountryCode: "MT", CityID: "tarxien"},
	{CountryCode: "MT", CityID: "gozo"},
	{CountryCode: "MT", CityID: "victoria-gozo"},
	{CountryCode: "MT", CityID: "xaghra"},
	{CountryCode: "MT", CityID: "xlendi"},
	{CountryCode: "MT", CityID: "marsalforn"},
	{CountryCode: "MT", CityID: "comino"},
	{CountryCode: "CY", CityID: "nicosia"},
	{CountryCode: "CY", CityID: "limassol"},
	{CountryCode: "CY", CityID: "larnaca"},
	{CountryCode: "CY", CityID: "paphos"},
	{CountryCode: "CY", CityID: "ayia-napa"},
	{CountryCode: "CY", CityID: "protaras"},
	{CountryCode: "CY", CityID: "paralimni"},
	{CountryCode: "CY", CityID: "famagusta"},
	{CountryCode: "CY", CityID: "kyrenia"},
	{CountryCode: "CY", CityID: "troodos"},
	{CountryCode: "CY", CityID: "platres"},
	{CountryCode: "CY", CityID: "kakopetria"},
	{CountryCode: "CY", CityID: "omodos"},
	{CountryCode: "CY", CityID: "polis"},
	{CountryCode: "CY", CityID: "latchi"},
	{CountryCode: "CY", CityID: "coral-bay"},
	{CountryCode: "CY", CityID: "peyia"},
	{CountryCode: "CY", CityID: "kourion"},
	{CountryCode: "CY", CityID: "choirokoitia"},
	{CountryCode: "CY", CityID: "agros"},
	{CountryCode: "SC", CityID: "victoria"},
	{CountryCode: "SC", CityID: "beau-vallon"},
	{CountryCode: "SC", CityID: "eden-island"},
	{CountryCode: "SC", CityID: "port-glaud"},
	{CountryCode: "SC", CityID: "anse-royale"},
	{CountryCode: "SC", CityID: "takamaka"},
	{CountryCode: "SC", CityID: "mahe"},
	{CountryCode: "SC", CityID: "praslin"},
	{CountryCode: "SC", CityID: "baie-sainte-anne"},
	{CountryCode: "SC", CityID: "grand-anse-praslin"},
	{CountryCode: "SC", CityID: "la-digue"},
	{CountryCode: "SC", CityID: "anse-reunion"},
	{CountryCode: "SC", CityID: "la-passe"},
	{CountryCode: "SC", CityID: "curieuse-island"},
	{CountryCode: "SC", CityID: "cousin-island"},
	{CountryCode: "SC", CityID: "silhouette-island"},
	{CountryCode: "SC", CityID: "sainte-anne-island"},
	{CountryCode: "SC", CityID: "moyenne-island"},
	{CountryCode: "SC", CityID: "cerf-island"},
	{CountryCode: "SC", CityID: "felicite-island"},
	{CountryCode: "SC", CityID: "ile-cocos"},
	{CountryCode: "PL", CityID: "warsaw"},
	{CountryCode: "PL", CityID: "krakow"},
	{CountryCode: "PL", CityID: "wieliczka"},
	{CountryCode: "PL", CityID: "oswiecim"},
	{CountryCode: "PL", CityID: "zakopane"},
	{CountryCode: "PL", CityID: "gdansk"},
	{CountryCode: "PL", CityID: "sopot"},
	{CountryCode: "PL", CityID: "gdynia"},
	{CountryCode: "PL", CityID: "malbork"},
	{CountryCode: "PL", CityID: "torun"},
	{CountryCode: "PL", CityID: "wroclaw"},
	{CountryCode: "PL", CityID: "poznan"},
	{CountryCode: "PL", CityID: "lodz"},
	{CountryCode: "PL", CityID: "katowice"},
	{CountryCode: "PL", CityID: "chorzow"},
	{CountryCode: "PL", CityID: "lublin"},
	{CountryCode: "PL", CityID: "bialowieza"},
	{CountryCode: "PL", CityID: "bialystok"},
	{CountryCode: "PL", CityID: "czestochowa"},
	{CountryCode: "PL", CityID: "zamosc"},
	{CountryCode: "PL", CityID: "szczecin"},
	{CountryCode: "MX", CityID: "mexico-city"},
	{CountryCode: "MX", CityID: "teotihuacan"},
	{CountryCode: "MX", CityID: "puebla"},
	{CountryCode: "MX", CityID: "cholula"},
	{CountryCode: "MX", CityID: "cuernavaca"},
	{CountryCode: "MX", CityID: "cancun"},
	{CountryCode: "MX", CityID: "isla-mujeres"},
	{CountryCode: "MX", CityID: "playa-del-carmen"},
	{CountryCode: "MX", CityID: "tulum"},
	{CountryCode: "MX", CityID: "cozumel"},
	{CountryCode: "MX", CityID: "merida"},
	{CountryCode: "MX", CityID: "valladolid"},
	{CountryCode: "MX", CityID: "chichen-itza"},
	{CountryCode: "MX", CityID: "uxmal"},
	{CountryCode: "MX", CityID: "los-cabos"},
	{CountryCode: "MX", CityID: "cabo-san-lucas"},
	{CountryCode: "MX", CityID: "san-jose-del-cabo"},
	{CountryCode: "MX", CityID: "la-paz-mexico"},
	{CountryCode: "MX", CityID: "puerto-vallarta"},
	{CountryCode: "MX", CityID: "sayulita"},
	{CountryCode: "MX", CityID: "mazatlan"},
	{CountryCode: "MX", CityID: "acapulco"},
	{CountryCode: "MX", CityID: "zihuatanejo"},
	{CountryCode: "MX", CityID: "guadalajara"},
	{CountryCode: "MX", CityID: "tequila"},
	{CountryCode: "MX", CityID: "guanajuato"},
	{CountryCode: "MX", CityID: "san-miguel-de-allende"},
	{CountryCode: "MX", CityID: "queretaro"},
	{CountryCode: "MX", CityID: "oaxaca"},
	{CountryCode: "MX", CityID: "monte-alban"},
	{CountryCode: "MX", CityID: "san-cristobal-de-las-casas"},
	{CountryCode: "MX", CityID: "palenque"},
	{CountryCode: "MX", CityID: "monterrey"},
	{CountryCode: "BR", CityID: "rio-de-janeiro"},
	{CountryCode: "BR", CityID: "petropolis"},
	{CountryCode: "BR", CityID: "paraty"},
	{CountryCode: "BR", CityID: "buzios"},
	{CountryCode: "BR", CityID: "angra-dos-reis"},
	{CountryCode: "BR", CityID: "sao-paulo"},
	{CountryCode: "BR", CityID: "santos"},
	{CountryCode: "BR", CityID: "curitiba"},
	{CountryCode: "BR", CityID: "florianopolis"},
	{CountryCode: "BR", CityID: "foz-do-iguacu"},
	{CountryCode: "BR", CityID: "gramado"},
	{CountryCode: "BR", CityID: "porto-alegre"},
	{CountryCode: "BR", CityID: "salvador"},
	{CountryCode: "BR", CityID: "recife"},
	{CountryCode: "BR", CityID: "olinda"},
	{CountryCode: "BR", CityID: "porto-de-galinhas"},
	{CountryCode: "BR", CityID: "natal"},
	{CountryCode: "BR", CityID: "pipa"},
	{CountryCode: "BR", CityID: "fortaleza"},
	{CountryCode: "BR", CityID: "jericoacoara"},
	{CountryCode: "BR", CityID: "sao-luis"},
	{CountryCode: "BR", CityID: "lencois-maranhenses"},
	{CountryCode: "BR", CityID: "manaus"},
	{CountryCode: "BR", CityID: "belem"},
	{CountryCode: "BR", CityID: "brasilia"},
	{CountryCode: "BR", CityID: "bonito"},
	{CountryCode: "BR", CityID: "pantanal"},
	{CountryCode: "BR", CityID: "cuiaba"},
	{CountryCode: "BR", CityID: "chapada-dos-veadeiros"},
	{CountryCode: "BR", CityID: "ouro-preto"},
	{CountryCode: "BR", CityID: "belo-horizonte"},
	{CountryCode: "AR", CityID: "buenos-aires"},
	{CountryCode: "AR", CityID: "la-plata"},
	{CountryCode: "AR", CityID: "tigre"},
	{CountryCode: "AR", CityID: "mar-del-plata"},
	{CountryCode: "AR", CityID: "pinamar"},
	{CountryCode: "AR", CityID: "carilo"},
	{CountryCode: "AR", CityID: "villa-gesell"},
	{CountryCode: "AR", CityID: "mar-de-las-pampas"},
	{CountryCode: "AR", CityID: "san-clemente-del-tuyu"},
	{CountryCode: "AR", CityID: "bariloche"},
	{CountryCode: "AR", CityID: "el-calafate"},
	{CountryCode: "AR", CityID: "el-chalten"},
	{CountryCode: "AR", CityID: "ushuaia"},
	{CountryCode: "AR", CityID: "puerto-madryn"},
	{CountryCode: "AR", CityID: "peninsula-valdes"},
	{CountryCode: "AR", CityID: "puerto-iguazu"},
	{CountryCode: "AR", CityID: "iguazu-falls"},
	{CountryCode: "AR", CityID: "posadas"},
	{CountryCode: "AR", CityID: "corrientes"},
	{CountryCode: "AR", CityID: "esteros-del-ibera"},
	{CountryCode: "AR", CityID: "rosario"},
	{CountryCode: "AR", CityID: "salta"},
	{CountryCode: "AR", CityID: "jujuy"},
	{CountryCode: "AR", CityID: "purmamarca"},
	{CountryCode: "AR", CityID: "tilcara"},
	{CountryCode: "AR", CityID: "humahuaca"},
	{CountryCode: "AR", CityID: "cafayate"},
	{CountryCode: "AR", CityID: "tucuman"},
	{CountryCode: "AR", CityID: "mendoza"},
	{CountryCode: "AR", CityID: "san-rafael"},
	{CountryCode: "AR", CityID: "uspallata"},
	{CountryCode: "AR", CityID: "aconcagua"},
	{CountryCode: "AR", CityID: "cordoba-argentina"},
	{CountryCode: "AR", CityID: "villa-carlos-paz"},
	{CountryCode: "AB", CityID: "sukhum"},
	{CountryCode: "AB", CityID: "gagra"},
	{CountryCode: "AB", CityID: "pitsunda"},
	{CountryCode: "AB", CityID: "new-athos"},
	{CountryCode: "AB", CityID: "gudauta"},
	{CountryCode: "AB", CityID: "lake-ritsa"},
	{CountryCode: "AB", CityID: "tkvarcheli"},
	{CountryCode: "AB", CityID: "ochamchira"},
	{CountryCode: "AB", CityID: "gali"},
	{CountryCode: "AB", CityID: "otap"},
	{CountryCode: "CU", CityID: "havana"},
	{CountryCode: "CU", CityID: "vinales"},
	{CountryCode: "CU", CityID: "varadero"},
	{CountryCode: "CU", CityID: "matanzas"},
	{CountryCode: "CU", CityID: "playa-larga"},
	{CountryCode: "CU", CityID: "cayo-coco"},
	{CountryCode: "CU", CityID: "cayo-guillermo"},
	{CountryCode: "CU", CityID: "cayo-santa-maria"},
	{CountryCode: "CU", CityID: "trinidad"},
	{CountryCode: "CU", CityID: "cienfuegos"},
	{CountryCode: "CU", CityID: "santa-clara"},
	{CountryCode: "CU", CityID: "camaguey"},
	{CountryCode: "CU", CityID: "santiago-de-cuba"},
	{CountryCode: "CU", CityID: "holguin"},
	{CountryCode: "CU", CityID: "guardalavaca"},
	{CountryCode: "CU", CityID: "baracoa"},
	{CountryCode: "MA", CityID: "casablanca"},
	{CountryCode: "MA", CityID: "rabat"},
	{CountryCode: "MA", CityID: "tangier"},
	{CountryCode: "MA", CityID: "chefchaouen"},
	{CountryCode: "MA", CityID: "tetouan"},
	{CountryCode: "MA", CityID: "asilah"},
	{CountryCode: "MA", CityID: "marrakech"},
	{CountryCode: "MA", CityID: "ourika"},
	{CountryCode: "MA", CityID: "agafay"},
	{CountryCode: "MA", CityID: "lalla-takerkoust"},
	{CountryCode: "MA", CityID: "imlil"},
	{CountryCode: "MA", CityID: "ouzoud"},
	{CountryCode: "MA", CityID: "azilal"},
	{CountryCode: "MA", CityID: "fes"},
	{CountryCode: "MA", CityID: "meknes"},
	{CountryCode: "MA", CityID: "volubilis"},
	{CountryCode: "MA", CityID: "ifrane"},
	{CountryCode: "MA", CityID: "agadir"},
	{CountryCode: "MA", CityID: "essaouira"},
	{CountryCode: "MA", CityID: "taghazout"},
	{CountryCode: "MA", CityID: "ouarzazate"},
	{CountryCode: "MA", CityID: "merzouga"},
	{CountryCode: "PT", CityID: "lisbon"},
	{CountryCode: "PT", CityID: "sintra"},
	{CountryCode: "PT", CityID: "cascais"},
	{CountryCode: "PT", CityID: "setubal"},
	{CountryCode: "PT", CityID: "porto"},
	{CountryCode: "PT", CityID: "vila-nova-de-gaia"},
	{CountryCode: "PT", CityID: "braga"},
	{CountryCode: "PT", CityID: "guimaraes"},
	{CountryCode: "PT", CityID: "viana-do-castelo"},
	{CountryCode: "PT", CityID: "douro-valley"},
	{CountryCode: "PT", CityID: "coimbra"},
	{CountryCode: "PT", CityID: "aveiro"},
	{CountryCode: "PT", CityID: "nazare"},
	{CountryCode: "PT", CityID: "obidos"},
	{CountryCode: "PT", CityID: "fatima"},
	{CountryCode: "PT", CityID: "evora"},
	{CountryCode: "PT", CityID: "faro"},
	{CountryCode: "PT", CityID: "albufeira"},
	{CountryCode: "PT", CityID: "lagoa"},
	{CountryCode: "PT", CityID: "lagos"},
	{CountryCode: "PT", CityID: "portimao"},
	{CountryCode: "PT", CityID: "tavira"},
	{CountryCode: "PT", CityID: "sagres"},
	{CountryCode: "PT", CityID: "vilamoura"},
	{CountryCode: "PT", CityID: "loule"},
	{CountryCode: "PT", CityID: "carvoeiro"},
	{CountryCode: "PT", CityID: "funchal"},
	{CountryCode: "PT", CityID: "madeira"},
	{CountryCode: "PT", CityID: "ponta-delgada"},
	{CountryCode: "PT", CityID: "sao-miguel"},
	{CountryCode: "PT", CityID: "tomar"},
	{CountryCode: "PT", CityID: "batalha"},
	{CountryCode: "PT", CityID: "alcobaca"},
	{CountryCode: "PT", CityID: "peniche"},
	{CountryCode: "PT", CityID: "berlengas"},
	{CountryCode: "PT", CityID: "serra-da-estrela"},
	{CountryCode: "PT", CityID: "monsaraz"},
	{CountryCode: "PT", CityID: "comporta"},
	{CountryCode: "PT", CityID: "sesimbra"},
	{CountryCode: "PT", CityID: "peneda-geres"},
	{CountryCode: "PT", CityID: "porto-santo"},
	{CountryCode: "PT", CityID: "terceira"},
	{CountryCode: "PT", CityID: "pico"},
	{CountryCode: "PT", CityID: "faial"},
	{CountryCode: "IT", CityID: "rome"},
	{CountryCode: "IT", CityID: "milan"},
	{CountryCode: "IT", CityID: "venice"},
	{CountryCode: "IT", CityID: "florence"},
	{CountryCode: "IT", CityID: "pisa"},
	{CountryCode: "IT", CityID: "siena"},
	{CountryCode: "IT", CityID: "lucca"},
	{CountryCode: "IT", CityID: "tivoli"},
	{CountryCode: "IT", CityID: "castelli-romani"},
	{CountryCode: "IT", CityID: "ostia"},
	{CountryCode: "IT", CityID: "lazio-coast"},
	{CountryCode: "IT", CityID: "valmontone"},
	{CountryCode: "IT", CityID: "verona"},
	{CountryCode: "IT", CityID: "lake-garda"},
	{CountryCode: "IT", CityID: "lake-como"},
	{CountryCode: "IT", CityID: "naples"},
	{CountryCode: "IT", CityID: "amalfi-coast"},
	{CountryCode: "IT", CityID: "capri"},
	{CountryCode: "IT", CityID: "pompeii"},
	{CountryCode: "IT", CityID: "mount-vesuvius"},
	{CountryCode: "IT", CityID: "sorrento"},
	{CountryCode: "IT", CityID: "palermo"},
	{CountryCode: "IT", CityID: "catania"},
	{CountryCode: "IT", CityID: "agrigento"},
	{CountryCode: "IT", CityID: "zingaro"},
	{CountryCode: "IT", CityID: "bari"},
	{CountryCode: "IT", CityID: "polignano-a-mare"},
	{CountryCode: "IT", CityID: "castellana-grotte"},
	{CountryCode: "IT", CityID: "andria"},
	{CountryCode: "IT", CityID: "alberobello"},
	{CountryCode: "IT", CityID: "matera"},
	{CountryCode: "IT", CityID: "tropea"},
	{CountryCode: "IT", CityID: "scilla"},
	{CountryCode: "IT", CityID: "reggio-calabria"},
	{CountryCode: "IT", CityID: "pollino"},
	{CountryCode: "IT", CityID: "sardinia"},
	{CountryCode: "IT", CityID: "la-maddalena"},
	{CountryCode: "IT", CityID: "costa-smeralda"},
	{CountryCode: "IT", CityID: "baunei"},
	{CountryCode: "IT", CityID: "barumini"},
	{CountryCode: "IT", CityID: "cagliari"},
	{CountryCode: "ES", CityID: "madrid"},
	{CountryCode: "ES", CityID: "barcelona"},
	{CountryCode: "ES", CityID: "toledo"},
	{CountryCode: "ES", CityID: "segovia"},
	{CountryCode: "ES", CityID: "el-escorial"},
	{CountryCode: "ES", CityID: "aranjuez"},
	{CountryCode: "ES", CityID: "sierra-guadarrama"},
	{CountryCode: "ES", CityID: "girona"},
	{CountryCode: "ES", CityID: "figueres"},
	{CountryCode: "ES", CityID: "montserrat"},
	{CountryCode: "ES", CityID: "costa-brava"},
	{CountryCode: "ES", CityID: "salou"},
	{CountryCode: "ES", CityID: "valencia"},
	{CountryCode: "ES", CityID: "alicante"},
	{CountryCode: "ES", CityID: "benidorm"},
	{CountryCode: "ES", CityID: "murcia"},
	{CountryCode: "ES", CityID: "cartagena"},
	{CountryCode: "ES", CityID: "elche"},
	{CountryCode: "ES", CityID: "calpe"},
	{CountryCode: "ES", CityID: "mallorca"},
	{CountryCode: "ES", CityID: "ibiza"},
	{CountryCode: "ES", CityID: "menorca"},
	{CountryCode: "ES", CityID: "seville"},
	{CountryCode: "ES", CityID: "cordoba"},
	{CountryCode: "ES", CityID: "granada"},
	{CountryCode: "ES", CityID: "malaga"},
	{CountryCode: "ES", CityID: "marbella"},
	{CountryCode: "ES", CityID: "ronda"},
	{CountryCode: "ES", CityID: "cadiz"},
	{CountryCode: "ES", CityID: "tarifa"},
	{CountryCode: "ES", CityID: "andalusia"},
	{CountryCode: "ES", CityID: "tenerife"},
	{CountryCode: "ES", CityID: "gran-canaria"},
	{CountryCode: "ES", CityID: "lanzarote"},
	{CountryCode: "ES", CityID: "fuerteventura"},
	{CountryCode: "ES", CityID: "bilbao"},
	{CountryCode: "ES", CityID: "san-sebastian"},
	{CountryCode: "ES", CityID: "pamplona"},
	{CountryCode: "ES", CityID: "santander"},
	{CountryCode: "ES", CityID: "asturias"},
	{CountryCode: "ES", CityID: "santiago-de-compostela"},
	{CountryCode: "ES", CityID: "a-coruna"},
	{CountryCode: "ES", CityID: "zaragoza"},
	{CountryCode: "LU", CityID: "luxembourg-city"},
	{CountryCode: "LU", CityID: "kirchberg"},
	{CountryCode: "LU", CityID: "clervaux"},
	{CountryCode: "LU", CityID: "vianden"},
	{CountryCode: "LU", CityID: "bourscheid"},
	{CountryCode: "LU", CityID: "wiltz"},
	{CountryCode: "LU", CityID: "esch-sur-sure"},
	{CountryCode: "LU", CityID: "diekirch"},
	{CountryCode: "LU", CityID: "ettelbruck"},
	{CountryCode: "LU", CityID: "echternach"},
	{CountryCode: "LU", CityID: "mullerthal"},
	{CountryCode: "LU", CityID: "berdorf"},
	{CountryCode: "LU", CityID: "beaufort"},
	{CountryCode: "LU", CityID: "larochette"},
	{CountryCode: "LU", CityID: "esch-sur-alzette"},
	{CountryCode: "LU", CityID: "belval"},
	{CountryCode: "LU", CityID: "differdange"},
	{CountryCode: "LU", CityID: "dudelange"},
	{CountryCode: "LU", CityID: "remich"},
	{CountryCode: "LU", CityID: "grevenmacher"},
	{CountryCode: "LU", CityID: "schengen"},
	{CountryCode: "LU", CityID: "mondorf-les-bains"},
	{CountryCode: "DE", CityID: "berlin"},
	{CountryCode: "DE", CityID: "potsdam"},
	{CountryCode: "DE", CityID: "hamburg"},
	{CountryCode: "DE", CityID: "bremen"},
	{CountryCode: "DE", CityID: "lubeck"},
	{CountryCode: "DE", CityID: "sylt"},
	{CountryCode: "DE", CityID: "rugen"},
	{CountryCode: "DE", CityID: "hannover"},
	{CountryCode: "DE", CityID: "wolfsburg"},
	{CountryCode: "DE", CityID: "munich"},
	{CountryCode: "DE", CityID: "nuremberg"},
	{CountryCode: "DE", CityID: "rothenburg-ob-der-tauber"},
	{CountryCode: "DE", CityID: "fussen"},
	{CountryCode: "DE", CityID: "garmisch-partenkirchen"},
	{CountryCode: "DE", CityID: "berchtesgaden"},
	{CountryCode: "DE", CityID: "rust"},
	{CountryCode: "DE", CityID: "cologne"},
	{CountryCode: "DE", CityID: "dusseldorf"},
	{CountryCode: "DE", CityID: "bonn"},
	{CountryCode: "DE", CityID: "frankfurt"},
	{CountryCode: "DE", CityID: "mainz"},
	{CountryCode: "DE", CityID: "koblenz"},
	{CountryCode: "DE", CityID: "trier"},
	{CountryCode: "DE", CityID: "heidelberg"},
	{CountryCode: "DE", CityID: "stuttgart"},
	{CountryCode: "DE", CityID: "baden-baden"},
	{CountryCode: "DE", CityID: "freiburg"},
	{CountryCode: "DE", CityID: "dresden"},
	{CountryCode: "DE", CityID: "leipzig"},
	{CountryCode: "DE", CityID: "weimar"},
	{CountryCode: "DE", CityID: "erfurt"},
	{CountryCode: "DE", CityID: "goslar"},
	{CountryCode: "DE", CityID: "wernigerode"},
	{CountryCode: "DE", CityID: "oberhausen"},
	{CountryCode: "AT", CityID: "vienna"},
	{CountryCode: "AT", CityID: "klosterneuburg"},
	{CountryCode: "AT", CityID: "laxenburg"},
	{CountryCode: "AT", CityID: "voesendorf"},
	{CountryCode: "AT", CityID: "petronell-carnuntum"},
	{CountryCode: "AT", CityID: "hinterbruehl"},
	{CountryCode: "AT", CityID: "melk"},
	{CountryCode: "AT", CityID: "wachau"},
	{CountryCode: "AT", CityID: "krems"},
	{CountryCode: "AT", CityID: "duernstein"},
	{CountryCode: "AT", CityID: "goettweig"},
	{CountryCode: "AT", CityID: "salzburg"},
	{CountryCode: "AT", CityID: "hallstatt"},
	{CountryCode: "AT", CityID: "st-wolfgang"},
	{CountryCode: "AT", CityID: "bad-ischl"},
	{CountryCode: "AT", CityID: "zell-am-see"},
	{CountryCode: "AT", CityID: "kaprun"},
	{CountryCode: "AT", CityID: "innsbruck"},
	{CountryCode: "AT", CityID: "mayrhofen"},
	{CountryCode: "AT", CityID: "kitzbuhel"},
	{CountryCode: "AT", CityID: "solden"},
	{CountryCode: "AT", CityID: "bregenz"},
	{CountryCode: "AT", CityID: "graz"},
	{CountryCode: "AT", CityID: "klagenfurt"},
	{CountryCode: "AT", CityID: "villach"},
	{CountryCode: "AT", CityID: "eisenstadt"},
	{CountryCode: "AT", CityID: "linz"},
	{CountryCode: "AT", CityID: "wels"},
	{CountryCode: "AT", CityID: "st-polten"},
	{CountryCode: "AT", CityID: "grossglockner"},
	{CountryCode: "CH", CityID: "zurich"},
	{CountryCode: "CH", CityID: "lucerne"},
	{CountryCode: "CH", CityID: "basel"},
	{CountryCode: "CH", CityID: "schaffhausen"},
	{CountryCode: "CH", CityID: "bern"},
	{CountryCode: "CH", CityID: "interlaken"},
	{CountryCode: "CH", CityID: "grindelwald"},
	{CountryCode: "CH", CityID: "lauterbrunnen"},
	{CountryCode: "CH", CityID: "jungfraujoch"},
	{CountryCode: "CH", CityID: "thun"},
	{CountryCode: "CH", CityID: "geneva"},
	{CountryCode: "CH", CityID: "lausanne"},
	{CountryCode: "CH", CityID: "montreux"},
	{CountryCode: "CH", CityID: "vevey"},
	{CountryCode: "CH", CityID: "gruyeres"},
	{CountryCode: "CH", CityID: "zermatt"},
	{CountryCode: "CH", CityID: "lugano"},
	{CountryCode: "CH", CityID: "locarno"},
	{CountryCode: "CH", CityID: "bellinzona"},
	{CountryCode: "CH", CityID: "ascona"},
	{CountryCode: "CH", CityID: "st-moritz"},
	{CountryCode: "CH", CityID: "davos"},
	{CountryCode: "CH", CityID: "chur"},
	{CountryCode: "CH", CityID: "swiss-national-park"},
	{CountryCode: "SE", CityID: "stockholm"},
	{CountryCode: "SE", CityID: "uppsala"},
	{CountryCode: "SE", CityID: "sigtuna"},
	{CountryCode: "SE", CityID: "drottningholm"},
	{CountryCode: "SE", CityID: "gothenburg"},
	{CountryCode: "SE", CityID: "malmo"},
	{CountryCode: "SE", CityID: "lund"},
	{CountryCode: "SE", CityID: "helsingborg"},
	{CountryCode: "SE", CityID: "kiruna"},
	{CountryCode: "SE", CityID: "abisko"},
	{CountryCode: "SE", CityID: "jukkasjarvi"},
	{CountryCode: "SE", CityID: "lulea"},
	{CountryCode: "SE", CityID: "umea"},
	{CountryCode: "SE", CityID: "visby"},
	{CountryCode: "SE", CityID: "kalmar"},
	{CountryCode: "SE", CityID: "vaxjo"},
	{CountryCode: "SE", CityID: "karlskrona"},
	{CountryCode: "SE", CityID: "oland"},
	{CountryCode: "SE", CityID: "orebro"},
	{CountryCode: "SE", CityID: "linkoping"},
	{CountryCode: "SE", CityID: "norrkoping"},
	{CountryCode: "SE", CityID: "vasteras"},
	{CountryCode: "SE", CityID: "jonkoping"},
	{CountryCode: "SE", CityID: "falun"},
	{CountryCode: "SE", CityID: "mora"},
	{CountryCode: "SE", CityID: "are"},
	{CountryCode: "SE", CityID: "ostersund"},
	{CountryCode: "CZ", CityID: "prague"},
	{CountryCode: "CZ", CityID: "karlstejn"},
	{CountryCode: "CZ", CityID: "kutna-hora"},
	{CountryCode: "CZ", CityID: "brno"},
	{CountryCode: "CZ", CityID: "lednice-valtice"},
	{CountryCode: "CZ", CityID: "mikulov"},
	{CountryCode: "CZ", CityID: "moravian-karst"},
	{CountryCode: "CZ", CityID: "cesky-krumlov"},
	{CountryCode: "CZ", CityID: "ceske-budejovice"},
	{CountryCode: "CZ", CityID: "sumava"},
	{CountryCode: "CZ", CityID: "telc"},
	{CountryCode: "CZ", CityID: "trebic"},
	{CountryCode: "CZ", CityID: "karlovy-vary"},
	{CountryCode: "CZ", CityID: "marianske-lazne"},
	{CountryCode: "CZ", CityID: "plzen"},
	{CountryCode: "CZ", CityID: "litomysl"},
	{CountryCode: "CZ", CityID: "olomouc"},
	{CountryCode: "CZ", CityID: "ostrava"},
	{CountryCode: "CZ", CityID: "liberec"},
	{CountryCode: "CZ", CityID: "hradec-kralove"},
	{CountryCode: "CZ", CityID: "pardubice"},
	{CountryCode: "CZ", CityID: "bohemian-switzerland"},
	{CountryCode: "CZ", CityID: "cesky-raj"},
	{CountryCode: "CZ", CityID: "krkonose"},
	{CountryCode: "FR", CityID: "paris"},
	{CountryCode: "FR", CityID: "versailles"},
	{CountryCode: "FR", CityID: "fontainebleau"},
	{CountryCode: "FR", CityID: "disneyland-paris"},
	{CountryCode: "FR", CityID: "loire-valley"},
	{CountryCode: "FR", CityID: "mont-saint-michel"},
	{CountryCode: "FR", CityID: "normandy"},
	{CountryCode: "FR", CityID: "saint-malo"},
	{CountryCode: "FR", CityID: "rennes"},
	{CountryCode: "FR", CityID: "nantes"},
	{CountryCode: "FR", CityID: "bordeaux"},
	{CountryCode: "FR", CityID: "dordogne"},
	{CountryCode: "FR", CityID: "toulouse"},
	{CountryCode: "FR", CityID: "carcassonne"},
	{CountryCode: "FR", CityID: "montpellier"},
	{CountryCode: "FR", CityID: "biarritz"},
	{CountryCode: "FR", CityID: "lourdes"},
	{CountryCode: "FR", CityID: "pyrenees"},
	{CountryCode: "FR", CityID: "lyon"},
	{CountryCode: "FR", CityID: "dijon"},
	{CountryCode: "FR", CityID: "beaune"},
	{CountryCode: "FR", CityID: "strasbourg"},
	{CountryCode: "FR", CityID: "colmar"},
	{CountryCode: "FR", CityID: "reims"},
	{CountryCode: "FR", CityID: "lille"},
	{CountryCode: "FR", CityID: "nice"},
	{CountryCode: "FR", CityID: "cannes"},
	{CountryCode: "FR", CityID: "antibes"},
	{CountryCode: "FR", CityID: "saint-tropez"},
	{CountryCode: "FR", CityID: "marseille"},
	{CountryCode: "FR", CityID: "aix-en-provence"},
	{CountryCode: "FR", CityID: "avignon"},
	{CountryCode: "FR", CityID: "arles"},
	{CountryCode: "FR", CityID: "verdon"},
	{CountryCode: "FR", CityID: "chamonix"},
	{CountryCode: "FR", CityID: "annecy"},
	{CountryCode: "GB", CityID: "london"},
	{CountryCode: "GB", CityID: "windsor"},
	{CountryCode: "GB", CityID: "oxford"},
	{CountryCode: "GB", CityID: "cambridge"},
	{CountryCode: "GB", CityID: "bath"},
	{CountryCode: "GB", CityID: "bristol"},
	{CountryCode: "GB", CityID: "cotswolds"},
	{CountryCode: "GB", CityID: "stonehenge"},
	{CountryCode: "GB", CityID: "salisbury"},
	{CountryCode: "GB", CityID: "brighton"},
	{CountryCode: "GB", CityID: "canterbury"},
	{CountryCode: "GB", CityID: "bournemouth"},
	{CountryCode: "GB", CityID: "jurassic-coast"},
	{CountryCode: "GB", CityID: "cornwall"},
	{CountryCode: "GB", CityID: "devon"},
	{CountryCode: "GB", CityID: "stratford-upon-avon"},
	{CountryCode: "GB", CityID: "york"},
	{CountryCode: "GB", CityID: "manchester"},
	{CountryCode: "GB", CityID: "liverpool"},
	{CountryCode: "GB", CityID: "birmingham"},
	{CountryCode: "GB", CityID: "lake-district"},
	{CountryCode: "GB", CityID: "peak-district"},
	{CountryCode: "GB", CityID: "newcastle"},
	{CountryCode: "GB", CityID: "leeds"},
	{CountryCode: "GB", CityID: "edinburgh"},
	{CountryCode: "GB", CityID: "glasgow"},
	{CountryCode: "GB", CityID: "inverness"},
	{CountryCode: "GB", CityID: "highlands"},
	{CountryCode: "GB", CityID: "isle-of-skye"},
	{CountryCode: "GB", CityID: "loch-ness"},
	{CountryCode: "GB", CityID: "aberdeen"},
	{CountryCode: "GB", CityID: "st-andrews"},
	{CountryCode: "GB", CityID: "cardiff"},
	{CountryCode: "GB", CityID: "snowdonia"},
	{CountryCode: "GB", CityID: "conwy"},
	{CountryCode: "GB", CityID: "pembrokeshire"},
	{CountryCode: "GB", CityID: "belfast"},
	{CountryCode: "GB", CityID: "giants-causeway"},
	{CountryCode: "GB", CityID: "derry"},
	{CountryCode: "AU", CityID: "sydney"},
	{CountryCode: "AU", CityID: "blue-mountains"},
	{CountryCode: "AU", CityID: "canberra"},
	{CountryCode: "AU", CityID: "byron-bay"},
	{CountryCode: "AU", CityID: "melbourne"},
	{CountryCode: "AU", CityID: "great-ocean-road"},
	{CountryCode: "AU", CityID: "phillip-island"},
	{CountryCode: "AU", CityID: "hobart"},
	{CountryCode: "AU", CityID: "launceston"},
	{CountryCode: "AU", CityID: "brisbane"},
	{CountryCode: "AU", CityID: "gold-coast"},
	{CountryCode: "AU", CityID: "sunshine-coast"},
	{CountryCode: "AU", CityID: "noosa"},
	{CountryCode: "AU", CityID: "cairns"},
	{CountryCode: "AU", CityID: "port-douglas"},
	{CountryCode: "AU", CityID: "kuranda"},
	{CountryCode: "AU", CityID: "airlie-beach"},
	{CountryCode: "AU", CityID: "whitsundays"},
	{CountryCode: "AU", CityID: "adelaide"},
	{CountryCode: "AU", CityID: "barossa-valley"},
	{CountryCode: "AU", CityID: "kangaroo-island"},
	{CountryCode: "AU", CityID: "darwin"},
	{CountryCode: "AU", CityID: "kakadu"},
	{CountryCode: "AU", CityID: "alice-springs"},
	{CountryCode: "AU", CityID: "uluru"},
	{CountryCode: "AU", CityID: "perth"},
	{CountryCode: "AU", CityID: "fremantle"},
	{CountryCode: "AU", CityID: "rottnest-island"},
	{CountryCode: "AU", CityID: "margaret-river"},
	{CountryCode: "AU", CityID: "broome"},
	{CountryCode: "NZ", CityID: "auckland"},
	{CountryCode: "NZ", CityID: "waiheke-island"},
	{CountryCode: "NZ", CityID: "waitakere-ranges"},
	{CountryCode: "NZ", CityID: "rotorua"},
	{CountryCode: "NZ", CityID: "taupo"},
	{CountryCode: "NZ", CityID: "waitomo"},
	{CountryCode: "NZ", CityID: "matamata"},
	{CountryCode: "NZ", CityID: "tauranga"},
	{CountryCode: "NZ", CityID: "mount-maunganui"},
	{CountryCode: "NZ", CityID: "tongariro"},
	{CountryCode: "NZ", CityID: "napier"},
	{CountryCode: "NZ", CityID: "wellington"},
	{CountryCode: "NZ", CityID: "christchurch"},
	{CountryCode: "NZ", CityID: "kaikoura"},
	{CountryCode: "NZ", CityID: "nelson"},
	{CountryCode: "NZ", CityID: "abel-tasman"},
	{CountryCode: "NZ", CityID: "dunedin"},
	{CountryCode: "NZ", CityID: "otago-peninsula"},
	{CountryCode: "NZ", CityID: "queenstown"},
	{CountryCode: "NZ", CityID: "arrowtown"},
	{CountryCode: "NZ", CityID: "wanaka"},
	{CountryCode: "NZ", CityID: "tekapo"},
	{CountryCode: "NZ", CityID: "aoraki-mount-cook"},
	{CountryCode: "NZ", CityID: "fiordland"},
	{CountryCode: "NZ", CityID: "milford-sound"},
	{CountryCode: "NZ", CityID: "franz-josef"},
	{CountryCode: "NZ", CityID: "fox-glacier"},
	{CountryCode: "TZ", CityID: "dar-es-salaam"},
	{CountryCode: "TZ", CityID: "bagamoyo"},
	{CountryCode: "TZ", CityID: "tanga"},
	{CountryCode: "TZ", CityID: "pangani"},
	{CountryCode: "TZ", CityID: "saadani"},
	{CountryCode: "TZ", CityID: "mafia-island"},
	{CountryCode: "TZ", CityID: "zanzibar-city"},
	{CountryCode: "TZ", CityID: "stone-town"},
	{CountryCode: "TZ", CityID: "nungwi"},
	{CountryCode: "TZ", CityID: "kendwa"},
	{CountryCode: "TZ", CityID: "paje"},
	{CountryCode: "TZ", CityID: "jambiani"},
	{CountryCode: "TZ", CityID: "jozani"},
	{CountryCode: "TZ", CityID: "mnemba"},
	{CountryCode: "TZ", CityID: "arusha"},
	{CountryCode: "TZ", CityID: "moshi"},
	{CountryCode: "TZ", CityID: "kilimanjaro"},
	{CountryCode: "TZ", CityID: "mount-meru"},
	{CountryCode: "TZ", CityID: "serengeti"},
	{CountryCode: "TZ", CityID: "ngorongoro"},
	{CountryCode: "TZ", CityID: "tarangire"},
	{CountryCode: "TZ", CityID: "lake-manyara"},
	{CountryCode: "TZ", CityID: "karatu"},
	{CountryCode: "TZ", CityID: "dodoma"},
	{CountryCode: "TZ", CityID: "morogoro"},
	{CountryCode: "TZ", CityID: "mikumi"},
	{CountryCode: "TZ", CityID: "ruaha"},
	{CountryCode: "TZ", CityID: "nyerere"},
	{CountryCode: "TZ", CityID: "iringa"},
	{CountryCode: "TZ", CityID: "udzungwa"},
	{CountryCode: "TZ", CityID: "mbeya"},
	{CountryCode: "TZ", CityID: "kitulo"},
	{CountryCode: "TZ", CityID: "mwanza"},
	{CountryCode: "TZ", CityID: "rubondo-island"},
	{CountryCode: "TZ", CityID: "kigoma"},
	{CountryCode: "TZ", CityID: "gombe"},
	{CountryCode: "TZ", CityID: "mahale"},
	{CountryCode: "TZ", CityID: "tabora"},
	{CountryCode: "KE", CityID: "nairobi"},
	{CountryCode: "KE", CityID: "karen"},
	{CountryCode: "KE", CityID: "langata"},
	{CountryCode: "KE", CityID: "kiambu"},
	{CountryCode: "KE", CityID: "naivasha"},
	{CountryCode: "KE", CityID: "mount-kenya"},
	{CountryCode: "KE", CityID: "aberdares"},
	{CountryCode: "KE", CityID: "nyeri"},
	{CountryCode: "KE", CityID: "masai-mara"},
	{CountryCode: "KE", CityID: "narok"},
	{CountryCode: "KE", CityID: "nakuru"},
	{CountryCode: "KE", CityID: "lake-nakuru"},
	{CountryCode: "KE", CityID: "lake-naivasha"},
	{CountryCode: "KE", CityID: "hells-gate"},
	{CountryCode: "KE", CityID: "lake-elementaita"},
	{CountryCode: "KE", CityID: "lake-bogoria"},
	{CountryCode: "KE", CityID: "lake-baringo"},
	{CountryCode: "KE", CityID: "eldoret"},
	{CountryCode: "KE", CityID: "kericho"},
	{CountryCode: "KE", CityID: "mombasa"},
	{CountryCode: "KE", CityID: "diani"},
	{CountryCode: "KE", CityID: "malindi"},
	{CountryCode: "KE", CityID: "watamu"},
	{CountryCode: "KE", CityID: "lamu"},
	{CountryCode: "KE", CityID: "kilifi"},
	{CountryCode: "KE", CityID: "shimoni"},
	{CountryCode: "KE", CityID: "kisite-mpunguti"},
	{CountryCode: "KE", CityID: "amboseli"},
	{CountryCode: "KE", CityID: "tsavo-east"},
	{CountryCode: "KE", CityID: "tsavo-west"},
	{CountryCode: "KE", CityID: "samburu"},
	{CountryCode: "KE", CityID: "nanyuki"},
	{CountryCode: "KE", CityID: "laikipia"},
	{CountryCode: "KE", CityID: "ol-pejeta"},
	{CountryCode: "KE", CityID: "meru"},
	{CountryCode: "KE", CityID: "marsabit"},
	{CountryCode: "KE", CityID: "lake-turkana"},
	{CountryCode: "KE", CityID: "kisumu"},
	{CountryCode: "KE", CityID: "lake-victoria"},
	{CountryCode: "KE", CityID: "kakamega"},
	{CountryCode: "KE", CityID: "kitale"},
	{CountryCode: "KE", CityID: "rusinga-island"},
	{CountryCode: "KE", CityID: "ndere-island"},
}

var attractionCityFilterValues = append([]attractionCityReference{
	{CountryCode: "ID", CityID: "bali"},
	{CountryCode: "CN", CityID: "hainan"},
}, attractionCityValues...)

var attractionCurrencyValues = []string{"KZT", "KGS", "TJS", "MNT", "ISK", "BYN", "RSD", "UAH", "UZS", "USD", "CAD", "SGD", "EUR", "GBP", "CHF", "DKK", "SEK", "CZK", "RUB", "AUD", "NZD", "TZS", "KES", "TRY", "AED", "EGP", "MYR", "LKR", "INR", "VND", "THB", "PHP", "IDR", "MVR", "SCR", "PLN", "MXN", "BRL", "ARS", "CUP", "MAD", "GEL", "AZN", "AMD", "CNY", "KRW", "JPY"}

func attractionInputFromItem(item *model.AdminAttraction) model.AttractionInput {
	if item == nil {
		return model.AttractionInput{DefaultLocale: "ru", CountryCode: "KZ", Status: "PUBLISHED", Category: "NATURE"}
	}
	visitInfo := item.VisitInfo
	return model.AttractionInput{
		Title:             item.Title,
		Description:       item.Description,
		DefaultLocale:     item.DefaultLocale,
		Translations:      item.Translations,
		CountryCode:       item.CountryCode,
		CityID:            item.CityID,
		AccessCities:      item.AccessCities,
		DepartureCities:   item.DepartureCities,
		Latitude:          item.Latitude,
		Longitude:         item.Longitude,
		LocationSourceURL: item.LocationSourceURL,
		Category:          item.Category,
		PriceAmount:       item.PriceAmount,
		PriceCurrency:     item.PriceCurrency,
		DurationValue:     item.DurationValue,
		DurationUnit:      item.DurationUnit,
		Spots:             item.Spots,
		Status:            item.Status,
		Tags:              item.Tags,
		VisitInfo:         &visitInfo,
	}
}

func attractionCategoryText(locale string, category string) string {
	raw := strings.TrimSpace(category)
	if raw == "" {
		return "-"
	}
	key := normalizeAttractionCode(raw)
	if names, ok := attractionCategoryNames[key]; ok {
		return localizedValue(locale, names)
	}
	return humanizeCityID(strings.ToLower(raw))
}

func attractionCityText(locale string, countryCode string, cityID string) string {
	city := displayReferenceCityName(locale, cityID)
	country := countryText(locale, countryCode)
	if city == "" && country == "" {
		return "-"
	}
	if city == "" {
		return country
	}
	if country == "" {
		return city
	}
	return city + ", " + country
}

func countryText(locale string, countryCode string) string {
	return displayCountryName(locale, countryCode)
}

func attractionCityNameText(locale string, cityID string) string {
	return displayReferenceCityName(locale, cityID)
}

func attractionCurrencyText(locale string, currency string) string {
	switch strings.ToUpper(strings.TrimSpace(currency)) {
	case "KZT":
		if locale == localeRU {
			return "Казахстанский тенге"
		}
		return "Kazakhstani tenge"
	case "KGS":
		if locale == localeRU {
			return "Киргизский сом"
		}
		return "Kyrgyzstani som"
	case "TJS":
		if locale == localeRU {
			return "Таджикский сомони"
		}
		return "Tajikistani somoni"
	case "MNT":
		if locale == localeRU {
			return "Монгольский тугрик"
		}
		return "Mongolian tugrik"
	case "ISK":
		if locale == localeRU {
			return "Исландская крона"
		}
		return "Icelandic krona"
	case "BYN":
		if locale == localeRU {
			return "Белорусский рубль"
		}
		return "Belarusian ruble"
	case "RSD":
		if locale == localeRU {
			return "Сербский динар"
		}
		return "Serbian dinar"
	case "UAH":
		if locale == localeRU {
			return "Украинская гривна"
		}
		return "Ukrainian hryvnia"
	case "UZS":
		if locale == localeRU {
			return "Узбекский сум"
		}
		return "Uzbekistani som"
	case "USD":
		if locale == localeRU {
			return "Доллар США"
		}
		return "US dollar"
	case "CAD":
		if locale == localeRU {
			return "Канадский доллар"
		}
		return "Canadian dollar"
	case "SGD":
		if locale == localeRU {
			return "Сингапурский доллар"
		}
		return "Singapore dollar"
	case "EUR":
		if locale == localeRU {
			return "Евро"
		}
		return "Euro"
	case "GBP":
		if locale == localeRU {
			return "Британский фунт"
		}
		return "British pound"
	case "CHF":
		if locale == localeRU {
			return "Швейцарский франк"
		}
		return "Swiss franc"
	case "DKK":
		if locale == localeRU {
			return "Датская крона"
		}
		return "Danish krone"
	case "SEK":
		if locale == localeRU {
			return "Шведская крона"
		}
		return "Swedish krona"
	case "CZK":
		if locale == localeRU {
			return "Чешская крона"
		}
		return "Czech koruna"
	case "RUB":
		if locale == localeRU {
			return "Российский рубль"
		}
		return "Russian ruble"
	case "AUD":
		if locale == localeRU {
			return "Австралийский доллар"
		}
		return "Australian dollar"
	case "NZD":
		if locale == localeRU {
			return "Новозеландский доллар"
		}
		return "New Zealand dollar"
	case "TZS":
		if locale == localeRU {
			return "Танзанийский шиллинг"
		}
		return "Tanzanian shilling"
	case "KES":
		if locale == localeRU {
			return "Кенийский шиллинг"
		}
		return "Kenyan shilling"
	case "TRY":
		if locale == localeRU {
			return "Турецкая лира"
		}
		return "Turkish lira"
	case "AED":
		if locale == localeRU {
			return "Дирхам ОАЭ"
		}
		return "UAE dirham"
	case "EGP":
		if locale == localeRU {
			return "Египетский фунт"
		}
		return "Egyptian pound"
	case "MYR":
		if locale == localeRU {
			return "Малайзийский ринггит"
		}
		return "Malaysian ringgit"
	case "LKR":
		if locale == localeRU {
			return "Шри-ланкийская рупия"
		}
		return "Sri Lankan rupee"
	case "INR":
		if locale == localeRU {
			return "Индийская рупия"
		}
		return "Indian rupee"
	case "VND":
		if locale == localeRU {
			return "Вьетнамский донг"
		}
		return "Vietnamese dong"
	case "THB":
		if locale == localeRU {
			return "Тайский бат"
		}
		return "Thai baht"
	case "PHP":
		if locale == localeRU {
			return "Филиппинское песо"
		}
		return "Philippine peso"
	case "IDR":
		if locale == localeRU {
			return "Индонезийская рупия"
		}
		return "Indonesian rupiah"
	case "MVR":
		if locale == localeRU {
			return "Мальдивская руфия"
		}
		return "Maldivian rufiyaa"
	case "SCR":
		if locale == localeRU {
			return "Сейшельская рупия"
		}
		return "Seychellois rupee"
	case "PLN":
		if locale == localeRU {
			return "Польский злотый"
		}
		return "Polish zloty"
	case "MXN":
		if locale == localeRU {
			return "Мексиканский песо"
		}
		return "Mexican peso"
	case "BRL":
		if locale == localeRU {
			return "Бразильский реал"
		}
		return "Brazilian real"
	case "ARS":
		if locale == localeRU {
			return "Аргентинский песо"
		}
		return "Argentine peso"
	case "CUP":
		if locale == localeRU {
			return "Кубинский песо"
		}
		return "Cuban peso"
	case "MAD":
		if locale == localeRU {
			return "Марокканский дирхам"
		}
		return "Moroccan dirham"
	case "GEL":
		if locale == localeRU {
			return "Грузинский лари"
		}
		return "Georgian lari"
	case "AZN":
		if locale == localeRU {
			return "Азербайджанский манат"
		}
		return "Azerbaijani manat"
	case "AMD":
		if locale == localeRU {
			return "Армянский драм"
		}
		return "Armenian dram"
	case "CNY":
		if locale == localeRU {
			return "Китайский юань"
		}
		return "Chinese yuan"
	case "KRW":
		if locale == localeRU {
			return "Южнокорейская вона"
		}
		return "South Korean won"
	case "JPY":
		if locale == localeRU {
			return "Японская иена"
		}
		return "Japanese yen"
	default:
		return strings.ToUpper(strings.TrimSpace(currency))
	}
}

func localizedAttractionValue(locale string, values map[string]map[string]string, key string) string {
	if item, ok := values[key]; ok {
		if value := strings.TrimSpace(item[locale]); value != "" {
			return value
		}
		if value := strings.TrimSpace(item[localeEN]); value != "" {
			return value
		}
	}
	return strings.TrimSpace(key)
}

func attractionLocaleText(locale string, languageCode string) string {
	code := strings.ToLower(strings.TrimSpace(languageCode))
	if names, ok := languageNames[code]; ok {
		return localizedValue(locale, names)
	}
	if code == "" {
		return "-"
	}
	return strings.ToUpper(code)
}

func attractionSourceText(locale string, source string) string {
	raw := strings.TrimSpace(source)
	if raw == "" {
		return "-"
	}
	key := normalizeAttractionCode(raw)
	if names, ok := attractionSourceNames[key]; ok {
		return localizedValue(locale, names)
	}
	return humanizeCityID(strings.ToLower(raw))
}

func attractionListMetaText(locale string, item model.AdminAttraction) string {
	return fmt.Sprintf("%s: %s · %s: %s",
		translate(locale, "field.defaultLocale"),
		attractionLocaleText(locale, item.DefaultLocale),
		translate(locale, "field.source"),
		attractionSourceText(locale, item.Source),
	)
}

func normalizeAttractionCode(raw string) string {
	value := strings.TrimSpace(raw)
	value = strings.ReplaceAll(value, "-", "_")
	value = strings.ReplaceAll(value, " ", "_")
	return strings.ToUpper(value)
}

func attractionMediaURL(fileID uuid.UUID) template.URL {
	if fileID == uuid.Nil {
		return ""
	}
	return template.URL("/admin/attraction-media/" + fileID.String())
}

func attractionMediaImageURL(item model.AdminAttractionMedia) template.URL {
	if item.FileID != uuid.Nil {
		return attractionMediaURL(item.FileID)
	}
	externalURL := strings.TrimSpace(item.ExternalURL)
	if externalURL == "" {
		return ""
	}
	parsed, err := url.Parse(externalURL)
	if err != nil || (parsed.Scheme != "http" && parsed.Scheme != "https") {
		return ""
	}
	return template.URL(externalURL)
}

func attractionMediaPosition(position int) int {
	if position < 0 {
		return 1
	}
	return position + 1
}

func attractionTagsText(tags []string) string {
	return strings.Join(tags, ", ")
}

func attractionCityLinksText(items []model.AttractionCityLink) string {
	parts := make([]string, 0, len(items))
	for _, item := range items {
		if strings.TrimSpace(item.CityID) == "" {
			continue
		}
		if strings.TrimSpace(item.CountryCode) != "" {
			parts = append(parts, strings.ToUpper(strings.TrimSpace(item.CountryCode))+":"+strings.ToLower(strings.TrimSpace(item.CityID)))
			continue
		}
		parts = append(parts, strings.ToLower(strings.TrimSpace(item.CityID)))
	}
	return strings.Join(parts, ", ")
}

func attractionVisitInfoValue(item *model.AttractionVisitInfo, field string) string {
	if item == nil {
		return ""
	}
	switch field {
	case "bestTime":
		return item.BestTime
	case "accessibility":
		return item.Accessibility
	case "openingHours":
		return item.OpeningHours
	default:
		return ""
	}
}

func attractionOptionalStringEquals(value *string, expected string) bool {
	if value == nil {
		return strings.TrimSpace(expected) == ""
	}
	return strings.EqualFold(strings.TrimSpace(*value), strings.TrimSpace(expected))
}

func attractionTranslationTitle(input model.AttractionInput, locale string) string {
	if tr, ok := input.Translations[locale]; ok {
		return tr.Title
	}
	if locale == input.DefaultLocale {
		return input.Title
	}
	return ""
}

func attractionTranslationDescription(input model.AttractionInput, locale string) string {
	if tr, ok := input.Translations[locale]; ok {
		return tr.Description
	}
	if locale == input.DefaultLocale {
		return input.Description
	}
	return ""
}

func attractionCategoryOptions(selected string) []AttractionOptionView {
	values := []string{"NATURE", "ARCHITECTURE", "MUSEUM", "BEACH", "PARK", "TEMPLE", "ENTERTAINMENT", "FOOD", "MARKET", "SHOPPING", "OTHER"}
	return attractionOptions(values, "attraction.category.", selected)
}

func attractionStatusOptions(selected string) []AttractionOptionView {
	values := []string{"DRAFT", "PUBLISHED"}
	return attractionOptions(values, "attraction.status.", selected)
}

func attractionCountryOptions(selected string) []AttractionOptionView {
	selected = strings.ToUpper(strings.TrimSpace(selected))
	if selected == "" {
		selected = "KZ"
	}
	return attractionValueOptions(attractionCountryValues, selected, true)
}

func attractionCountryFilterOptions(selected string) []AttractionOptionView {
	selected = strings.ToUpper(strings.TrimSpace(selected))
	return attractionValueOptions(attractionCountryValues, selected, true)
}

func attractionCityOptions(selected string) []AttractionOptionView {
	return attractionCityOptionsFromReferences(attractionCityValues, selected)
}

func attractionCityFilterOptions(selected string) []AttractionOptionView {
	return attractionCityOptionsFromReferences(attractionCityFilterValues, selected)
}

func attractionCityOptionsFromReferences(values []attractionCityReference, selected string) []AttractionOptionView {
	selected = strings.ToLower(strings.TrimSpace(selected))
	seen := make(map[string]bool, len(values)+1)
	out := make([]AttractionOptionView, 0, len(values)+1)
	for _, item := range values {
		country := strings.ToUpper(strings.TrimSpace(item.CountryCode))
		cityID := strings.ToLower(strings.TrimSpace(item.CityID))
		if country == "" || cityID == "" || seen[country+":"+cityID] {
			continue
		}
		seen[country+":"+cityID] = true
		out = append(out, AttractionOptionView{
			Value:       cityID,
			LabelKey:    cityID,
			Selected:    selected == cityID,
			CountryCode: country,
		})
	}
	if selected != "" {
		var found bool
		for _, item := range out {
			if item.Value == selected {
				found = true
				break
			}
		}
		if !found {
			out = append(out, AttractionOptionView{
				Value:       selected,
				LabelKey:    selected,
				Selected:    true,
				CountryCode: "KZ",
			})
		}
	}
	return out
}

func attractionCurrencyOptions(selected *string) []AttractionOptionView {
	value := ""
	if selected != nil {
		value = strings.ToUpper(strings.TrimSpace(*selected))
	}
	return attractionValueOptions(attractionCurrencyValues, value, true)
}

func attractionValueOptions(values []string, selected string, uppercase bool) []AttractionOptionView {
	seen := make(map[string]bool, len(values)+1)
	out := make([]AttractionOptionView, 0, len(values)+1)
	for _, value := range values {
		normalized := strings.TrimSpace(value)
		if uppercase {
			normalized = strings.ToUpper(normalized)
		} else {
			normalized = strings.ToLower(normalized)
		}
		if normalized == "" || seen[normalized] {
			continue
		}
		seen[normalized] = true
		out = append(out, AttractionOptionView{
			Value:    normalized,
			LabelKey: normalized,
			Selected: selected == normalized,
		})
	}
	if selected != "" && !seen[selected] {
		out = append(out, AttractionOptionView{
			Value:    selected,
			LabelKey: selected,
			Selected: true,
		})
	}
	return out
}

func attractionLocaleOptions(selected string) []AttractionOptionView {
	values := []string{"ru", "en", "kk"}
	return attractionOptions(values, "attraction.locale.", selected)
}

func attractionOptions(values []string, prefix string, selected string) []AttractionOptionView {
	selected = strings.ToUpper(strings.TrimSpace(selected))
	if strings.HasPrefix(prefix, "attraction.locale.") {
		selected = strings.ToLower(strings.TrimSpace(selected))
		if selected == "" {
			selected = "ru"
		}
	}
	out := make([]AttractionOptionView, 0, len(values))
	for _, value := range values {
		compare := value
		if strings.HasPrefix(prefix, "attraction.category.") || strings.HasPrefix(prefix, "attraction.status.") {
			compare = strings.ToUpper(value)
		}
		out = append(out, AttractionOptionView{
			Value:    value,
			LabelKey: prefix + value,
			Selected: selected == compare || (selected == "" && value == "PUBLISHED"),
		})
	}
	return out
}

func attractionListQuery(r valuesReader) AttractionFilterViewData {
	search := strings.TrimSpace(r.Get("q"))
	category := strings.ToUpper(strings.TrimSpace(r.Get("category")))
	status := strings.ToUpper(strings.TrimSpace(r.Get("status")))
	countryCode := strings.ToUpper(strings.TrimSpace(r.Get("country")))
	cityID := strings.ToLower(strings.TrimSpace(r.Get("city")))
	page := parseAttractionListPage(r.Get("page"))
	if countryCode == "" {
		cityID = ""
	}
	values := url.Values{}
	setAttractionQuery(values, "q", search)
	setAttractionQuery(values, "category", category)
	setAttractionQuery(values, "status", status)
	setAttractionQuery(values, "country", countryCode)
	setAttractionQuery(values, "city", cityID)
	return AttractionFilterViewData{
		Search:      search,
		Category:    category,
		Status:      status,
		CountryCode: countryCode,
		CityID:      cityID,
		Page:        page,
		Query:       values.Encode(),
	}
}

func parseAttractionListPage(raw string) int {
	page, err := strconv.Atoi(strings.TrimSpace(raw))
	if err != nil || page < 1 {
		return 1
	}
	return page
}

func attractionPagination(total int, filters AttractionFilterViewData) AttractionPaginationViewData {
	page := filters.Page
	if page < 1 {
		page = 1
	}
	totalPages := 0
	if total > 0 {
		totalPages = (total + attractionListPageSize - 1) / attractionListPageSize
	}
	from := 0
	to := 0
	if total > 0 {
		from = (page-1)*attractionListPageSize + 1
		to = page * attractionListPageSize
		if to > total {
			to = total
		}
		if from > total {
			from = total
		}
	}
	return AttractionPaginationViewData{
		Page:          page,
		PageSize:      attractionListPageSize,
		Total:         total,
		TotalPages:    totalPages,
		From:          from,
		To:            to,
		HasPrevious:   page > 1,
		HasNext:       totalPages > 0 && page < totalPages,
		PreviousQuery: attractionPageQuery(filters.Query, page-1),
		NextQuery:     attractionPageQuery(filters.Query, page+1),
	}
}

func attractionPageQuery(baseQuery string, page int) string {
	if page < 1 {
		page = 1
	}
	values, err := url.ParseQuery(strings.TrimSpace(baseQuery))
	if err != nil {
		values = url.Values{}
	}
	values.Set("page", strconv.Itoa(page))
	return values.Encode()
}

func attractionPaginationSummary(locale string, pagination AttractionPaginationViewData) string {
	if locale == localeRU {
		return fmt.Sprintf("Показано %d-%d из %d", pagination.From, pagination.To, pagination.Total)
	}
	return fmt.Sprintf("Showing %d-%d of %d", pagination.From, pagination.To, pagination.Total)
}

func attractionCityLinkOptions(selected []model.AttractionCityLink, fallbackCountry string) []AttractionCityLinkOptionView {
	visibleCountry := strings.ToUpper(strings.TrimSpace(fallbackCountry))
	if visibleCountry == "" {
		visibleCountry = "KZ"
	}
	selectedMap := make(map[string]model.AttractionCityLink, len(selected))
	for _, item := range selected {
		country := strings.ToUpper(strings.TrimSpace(item.CountryCode))
		if country == "" {
			country = visibleCountry
		}
		if country == "" {
			country = "KZ"
		}
		cityID := strings.ToLower(strings.TrimSpace(item.CityID))
		if cityID == "" {
			continue
		}
		selectedMap[country+":"+cityID] = model.AttractionCityLink{CountryCode: country, CityID: cityID}
	}

	out := make([]AttractionCityLinkOptionView, 0, len(attractionCityValues)+len(selectedMap))
	seen := make(map[string]bool, len(attractionCityValues)+len(selectedMap))
	for _, item := range attractionCityValues {
		country := strings.ToUpper(strings.TrimSpace(item.CountryCode))
		cityID := strings.ToLower(strings.TrimSpace(item.CityID))
		if country == "" || cityID == "" {
			continue
		}
		value := country + ":" + cityID
		_, selected := selectedMap[value]
		out = append(out, AttractionCityLinkOptionView{
			Value:       value,
			CountryCode: country,
			CityID:      cityID,
			Selected:    selected,
			Hidden:      country != visibleCountry,
		})
		seen[value] = true
	}
	for value, item := range selectedMap {
		if seen[value] {
			continue
		}
		out = append(out, AttractionCityLinkOptionView{
			Value:       value,
			CountryCode: item.CountryCode,
			CityID:      item.CityID,
			Selected:    true,
			Hidden:      item.CountryCode != visibleCountry,
		})
	}
	return out
}

type valuesReader interface {
	Get(string) string
}

func setAttractionQuery(values url.Values, key string, value string) {
	value = strings.TrimSpace(value)
	if value != "" {
		values.Set(key, value)
	}
}

func parseCityLinks(raw string, fallbackCountry string) []model.AttractionCityLink {
	return parseCityLinkValues([]string{raw}, fallbackCountry)
}

func parseCityLinkValues(values []string, fallbackCountry string) []model.AttractionCityLink {
	items := make([]string, 0, len(values))
	for _, value := range values {
		items = append(items, splitCSV(value)...)
	}
	allowedCountry := strings.ToUpper(strings.TrimSpace(fallbackCountry))
	out := make([]model.AttractionCityLink, 0, len(items))
	seen := make(map[string]bool, len(items))
	for _, item := range items {
		country := fallbackCountry
		city := item
		if strings.Contains(item, ":") {
			parts := strings.SplitN(item, ":", 2)
			country = parts[0]
			city = parts[1]
		}
		city = strings.ToLower(strings.TrimSpace(city))
		if city == "" {
			continue
		}
		country = strings.ToUpper(strings.TrimSpace(country))
		if allowedCountry != "" && country != "" && country != allowedCountry {
			continue
		}
		if country == "" {
			country = allowedCountry
		}
		if country == "" {
			country = "KZ"
		}
		key := country + ":" + city
		if seen[key] {
			continue
		}
		seen[key] = true
		out = append(out, model.AttractionCityLink{
			CountryCode: country,
			CityID:      city,
		})
	}
	return out
}

func parseOptionalFloat(raw string) (*float64, error) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return nil, nil
	}
	var value float64
	if _, err := fmt.Sscanf(raw, "%f", &value); err != nil {
		return nil, err
	}
	return &value, nil
}

func parseOptionalInt(raw string) (*int, error) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return nil, nil
	}
	var value int
	if _, err := fmt.Sscanf(raw, "%d", &value); err != nil {
		return nil, err
	}
	return &value, nil
}
