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

var attractionCountryValues = []string{"KZ", "RU", "VN", "TH", "PH", "ID", "MV", "TR", "AE", "GE", "AM", "CN", "KR", "JP", "EG", "MY"}

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
}

var attractionCityFilterValues = append([]attractionCityReference{
	{CountryCode: "ID", CityID: "bali"},
	{CountryCode: "CN", CityID: "hainan"},
}, attractionCityValues...)

var attractionCurrencyValues = []string{"KZT", "USD", "EUR", "TRY", "AED", "EGP", "MYR", "VND", "THB", "PHP", "IDR", "MVR", "GEL", "AMD", "CNY", "KRW", "JPY"}

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
	case "USD":
		if locale == localeRU {
			return "Доллар США"
		}
		return "US dollar"
	case "EUR":
		if locale == localeRU {
			return "Евро"
		}
		return "Euro"
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
	case "GEL":
		if locale == localeRU {
			return "Грузинский лари"
		}
		return "Georgian lari"
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
