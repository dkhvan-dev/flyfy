package http

import (
	"fmt"
	"strings"
	"unicode"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
)

const (
	genericRouteSummary     = "Compare guide offers for this route."
	genericRouteDescription = "Choose a guide, language, price, meeting point, and schedule before booking this route."
)

var countryNames = map[string]map[string]string{
	"KZ": {localeEN: "Kazakhstan", localeRU: "Казахстан"},
	"KG": {localeEN: "Kyrgyzstan", localeRU: "Кыргызстан"},
	"UZ": {localeEN: "Uzbekistan", localeRU: "Узбекистан"},
	"RU": {localeEN: "Russian Federation", localeRU: "Российская Федерация"},
	"VN": {localeEN: "Vietnam", localeRU: "Вьетнам"},
	"TH": {localeEN: "Thailand", localeRU: "Таиланд"},
	"PH": {localeEN: "Philippines", localeRU: "Филиппины"},
	"ID": {localeEN: "Indonesia", localeRU: "Индонезия"},
	"MV": {localeEN: "Maldives", localeRU: "Мальдивы"},
	"TR": {localeEN: "Turkey", localeRU: "Турция"},
	"AE": {localeEN: "United Arab Emirates", localeRU: "ОАЭ"},
	"GE": {localeEN: "Georgia", localeRU: "Грузия"},
	"AM": {localeEN: "Armenia", localeRU: "Армения"},
	"CN": {localeEN: "China", localeRU: "Китай"},
	"KR": {localeEN: "South Korea", localeRU: "Южная Корея"},
	"JP": {localeEN: "Japan", localeRU: "Япония"},
	"EG": {localeEN: "Egypt", localeRU: "Египет"},
	"MY": {localeEN: "Malaysia", localeRU: "Малайзия"},
	"LK": {localeEN: "Sri Lanka", localeRU: "Шри-Ланка"},
	"SC": {localeEN: "Seychelles", localeRU: "Сейшелы"},
	"PL": {localeEN: "Poland", localeRU: "Польша"},
	"MX": {localeEN: "Mexico", localeRU: "Мексика"},
	"BR": {localeEN: "Brazil", localeRU: "Бразилия"},
	"AB": {localeEN: "Abkhazia", localeRU: "Абхазия"},
	"CU": {localeEN: "Cuba", localeRU: "Куба"},
	"MA": {localeEN: "Morocco", localeRU: "Марокко"},
	"PT": {localeEN: "Portugal", localeRU: "Португалия"},
	"IT": {localeEN: "Italy", localeRU: "Италия"},
	"ES": {localeEN: "Spain", localeRU: "Испания"},
	"LU": {localeEN: "Luxembourg", localeRU: "Люксембург"},
	"DE": {localeEN: "Germany", localeRU: "Германия"},
	"AT": {localeEN: "Austria", localeRU: "Австрия"},
	"AU": {localeEN: "Australia", localeRU: "Австралия"},
	"TZ": {localeEN: "Tanzania", localeRU: "Танзания"},
	"KE": {localeEN: "Kenya", localeRU: "Кения"},
	"ME": {localeEN: "Montenegro", localeRU: "Черногория"},
	"IN": {localeEN: "India", localeRU: "Индия"},
	"MT": {localeEN: "Malta", localeRU: "Мальта"},
	"CY": {localeEN: "Cyprus", localeRU: "Кипр"},
	"AZ": {localeEN: "Azerbaijan", localeRU: "Азербайджан"},
	"US": {localeEN: "United States", localeRU: "США"},
}

var cityNames = map[string]map[string]string{
	"abu-simbel":       {localeEN: "Abu Simbel", localeRU: "Абу-Симбел"},
	"ain-sokhna":       {localeEN: "Ain Sokhna", localeRU: "Айн-Сохна"},
	"alexandria":       {localeEN: "Alexandria", localeRU: "Александрия"},
	"aswan":            {localeEN: "Aswan", localeRU: "Асуан"},
	"bahariya-oasis":   {localeEN: "Bahariya Oasis", localeRU: "Оазис Бахария"},
	"cairo":            {localeEN: "Cairo", localeRU: "Каир"},
	"dahab":            {localeEN: "Dahab", localeRU: "Дахаб"},
	"el-gouna":         {localeEN: "El Gouna", localeRU: "Эль-Гуна"},
	"fayoum":           {localeEN: "Fayoum", localeRU: "Фаюм"},
	"giza":             {localeEN: "Giza", localeRU: "Гиза"},
	"hurghada":         {localeEN: "Hurghada", localeRU: "Хургада"},
	"luxor":            {localeEN: "Luxor", localeRU: "Луксор"},
	"marsa-alam":       {localeEN: "Marsa Alam", localeRU: "Марса-Алам"},
	"north-coast":      {localeEN: "North Coast", localeRU: "Северное побережье"},
	"port-said":        {localeEN: "Port Said", localeRU: "Порт-Саид"},
	"saint-catherine":  {localeEN: "Saint Catherine", localeRU: "Сент-Кэтрин"},
	"sharm-el-sheikh":  {localeEN: "Sharm El Sheikh", localeRU: "Шарм-эль-Шейх"},
	"siwa":             {localeEN: "Siwa", localeRU: "Сива"},
	"suez":             {localeEN: "Suez", localeRU: "Суэц"},
	"white-desert":     {localeEN: "White Desert", localeRU: "Белая пустыня"},
	"alanya":           {localeEN: "Alanya", localeRU: "Аланья"},
	"ankara":           {localeEN: "Ankara", localeRU: "Анкара"},
	"antalya":          {localeEN: "Antalya", localeRU: "Анталья"},
	"artvin":           {localeEN: "Artvin", localeRU: "Артвин"},
	"avanos":           {localeEN: "Avanos", localeRU: "Аванос"},
	"belek":            {localeEN: "Belek", localeRU: "Белек"},
	"bodrum":           {localeEN: "Bodrum", localeRU: "Бодрум"},
	"cappadocia":       {localeEN: "Cappadocia", localeRU: "Каппадокия"},
	"cesme":            {localeEN: "Cesme", localeRU: "Чешме"},
	"denizli":          {localeEN: "Denizli", localeRU: "Денизли"},
	"fethiye":          {localeEN: "Fethiye", localeRU: "Фетхие"},
	"gaziantep":        {localeEN: "Gaziantep", localeRU: "Газиантеп"},
	"goreme":           {localeEN: "Goreme", localeRU: "Гёреме"},
	"istanbul":         {localeEN: "Istanbul", localeRU: "Стамбул"},
	"izmir":            {localeEN: "Izmir", localeRU: "Измир"},
	"kas":              {localeEN: "Kas", localeRU: "Каш"},
	"kemer":            {localeEN: "Kemer", localeRU: "Кемер"},
	"konya":            {localeEN: "Konya", localeRU: "Конья"},
	"mardin":           {localeEN: "Mardin", localeRU: "Мардин"},
	"marmaris":         {localeEN: "Marmaris", localeRU: "Мармарис"},
	"nevsehir":         {localeEN: "Nevsehir", localeRU: "Невшехир"},
	"oludeniz":         {localeEN: "Oludeniz", localeRU: "Олюдениз"},
	"pamukkale":        {localeEN: "Pamukkale", localeRU: "Памуккале"},
	"princes-islands":  {localeEN: "Princes' Islands", localeRU: "Принцевы острова"},
	"rize":             {localeEN: "Rize", localeRU: "Ризе"},
	"sanliurfa":        {localeEN: "Sanliurfa", localeRU: "Шанлыурфа"},
	"selcuk":           {localeEN: "Selcuk", localeRU: "Сельчук"},
	"side":             {localeEN: "Side", localeRU: "Сиде"},
	"trabzon":          {localeEN: "Trabzon", localeRU: "Трабзон"},
	"uchisar":          {localeEN: "Uchisar", localeRU: "Учхисар"},
	"urgup":            {localeEN: "Urgup", localeRU: "Ургюп"},
	"uzungol":          {localeEN: "Uzungol", localeRU: "Узунгёль"},
	"abu-dhabi":        {localeEN: "Abu Dhabi", localeRU: "Абу-Даби"},
	"ajman":            {localeEN: "Ajman", localeRU: "Аджман"},
	"aktau":            {localeEN: "Aktau", localeRU: "Актау"},
	"aktobe":           {localeEN: "Aktobe", localeRU: "Актобе"},
	"al-ain":           {localeEN: "Al Ain", localeRU: "Аль-Айн"},
	"almaty":           {localeEN: "Almaty", localeRU: "Алматы"},
	"amed":             {localeEN: "Amed", localeRU: "Амед"},
	"astana":           {localeEN: "Astana", localeRU: "Астана"},
	"aspindza":         {localeEN: "Aspindza", localeRU: "Аспиндза"},
	"ayutthaya":        {localeEN: "Ayutthaya", localeRU: "Аюттхая"},
	"atyrau":           {localeEN: "Atyrau", localeRU: "Атырау"},
	"bacolod":          {localeEN: "Bacolod", localeRU: "Баколод"},
	"baguio":           {localeEN: "Baguio", localeRU: "Багио"},
	"bali":             {localeEN: "Bali", localeRU: "Бали"},
	"banaue":           {localeEN: "Banaue", localeRU: "Банауэ"},
	"balkhash":         {localeEN: "Balkhash", localeRU: "Балхаш"},
	"baghdati":         {localeEN: "Baghdati", localeRU: "Багдати"},
	"bangkok":          {localeEN: "Bangkok", localeRU: "Бангкок"},
	"bakuriani":        {localeEN: "Bakuriani", localeRU: "Бакуриани"},
	"batumi":           {localeEN: "Batumi", localeRU: "Батуми"},
	"bedugul":          {localeEN: "Bedugul", localeRU: "Бедугул"},
	"bohol":            {localeEN: "Bohol", localeRU: "Бохол"},
	"boracay":          {localeEN: "Boracay", localeRU: "Боракай"},
	"borjomi":          {localeEN: "Borjomi", localeRU: "Боржоми"},
	"cagayan-de-oro":   {localeEN: "Cagayan de Oro", localeRU: "Кагаян-де-Оро"},
	"camiguin":         {localeEN: "Camiguin", localeRU: "Камигин"},
	"can-tho":          {localeEN: "Can Tho", localeRU: "Кантхо"},
	"cat-ba":           {localeEN: "Cat Ba", localeRU: "Катба"},
	"candidasa":        {localeEN: "Candidasa", localeRU: "Чандидаса"},
	"canggu":           {localeEN: "Canggu", localeRU: "Чангу"},
	"cebu-city":        {localeEN: "Cebu City", localeRU: "Себу"},
	"chakvistavi":      {localeEN: "Chakvistavi", localeRU: "Чаквистави"},
	"chengde":          {localeEN: "Chengde", localeRU: "Чэндэ"},
	"chengdu":          {localeEN: "Chengdu", localeRU: "Чэнду"},
	"chiang-mai":       {localeEN: "Chiang Mai", localeRU: "Чиангмай"},
	"chiang-rai":       {localeEN: "Chiang Rai", localeRU: "Чианграй"},
	"chiatura":         {localeEN: "Chiatura", localeRU: "Чиатура"},
	"chongqing":        {localeEN: "Chongqing", localeRU: "Чунцин"},
	"busan":            {localeEN: "Busan", localeRU: "Пусан"},
	"cheorwon":         {localeEN: "Cheorwon", localeRU: "Чхорвон"},
	"chuncheon":        {localeEN: "Chuncheon", localeRU: "Чхунчхон"},
	"daegu":            {localeEN: "Daegu", localeRU: "Тэгу"},
	"gangneung":        {localeEN: "Gangneung", localeRU: "Каннын"},
	"gapyeong":         {localeEN: "Gapyeong", localeRU: "Капхён"},
	"goseong":          {localeEN: "Goseong", localeRU: "Косон"},
	"gwacheon":         {localeEN: "Gwacheon", localeRU: "Квачхон"},
	"gyeongju":         {localeEN: "Gyeongju", localeRU: "Кёнджу"},
	"incheon":          {localeEN: "Incheon", localeRU: "Инчхон"},
	"jeju":             {localeEN: "Jeju", localeRU: "Чеджу"},
	"paju":             {localeEN: "Paju", localeRU: "Пхаджу"},
	"pyeongchang":      {localeEN: "Pyeongchang", localeRU: "Пхёнчхан"},
	"seogwipo":         {localeEN: "Seogwipo", localeRU: "Согвипхо"},
	"seoul":            {localeEN: "Seoul", localeRU: "Сеул"},
	"sokcho":           {localeEN: "Sokcho", localeRU: "Сокчхо"},
	"suwon":            {localeEN: "Suwon", localeRU: "Сувон"},
	"yangyang":         {localeEN: "Yangyang", localeRU: "Янъян"},
	"yongin":           {localeEN: "Yongin", localeRU: "Йонъин"},
	"aomori":           {localeEN: "Aomori", localeRU: "Аомори"},
	"asahikawa":        {localeEN: "Asahikawa", localeRU: "Асахикава"},
	"azumino":          {localeEN: "Azumino", localeRU: "Адзумино"},
	"beppu":            {localeEN: "Beppu", localeRU: "Бэппу"},
	"biei":             {localeEN: "Biei", localeRU: "Биэй"},
	"chatan":           {localeEN: "Chatan", localeRU: "Тятан"},
	"fujikawaguchiko":  {localeEN: "Fujikawaguchiko", localeRU: "Фудзикавагутико"},
	"fujiyoshida":      {localeEN: "Fujiyoshida", localeRU: "Фудзиёсида"},
	"fukuoka":          {localeEN: "Fukuoka", localeRU: "Фукуока"},
	"furano":           {localeEN: "Furano", localeRU: "Фурано"},
	"ginzan-onsen":     {localeEN: "Ginzan Onsen", localeRU: "Гиндзан-онсэн"},
	"gotemba":          {localeEN: "Gotemba", localeRU: "Готэмба"},
	"hakodate":         {localeEN: "Hakodate", localeRU: "Хакодате"},
	"hakone":           {localeEN: "Hakone", localeRU: "Хаконе"},
	"hatsukaichi":      {localeEN: "Hatsukaichi", localeRU: "Хацукаити"},
	"himeji":           {localeEN: "Himeji", localeRU: "Химэдзи"},
	"hiroshima":        {localeEN: "Hiroshima", localeRU: "Хиросима"},
	"ishigaki":         {localeEN: "Ishigaki", localeRU: "Исигаки"},
	"kagoshima":        {localeEN: "Kagoshima", localeRU: "Кагосима"},
	"kakunodate":       {localeEN: "Kakunodate", localeRU: "Какунодатэ"},
	"kamakura":         {localeEN: "Kamakura", localeRU: "Камакура"},
	"kamikochi":        {localeEN: "Kamikochi", localeRU: "Камикоти"},
	"kanazawa":         {localeEN: "Kanazawa", localeRU: "Канадзава"},
	"kobe":             {localeEN: "Kobe", localeRU: "Кобе"},
	"kumamoto":         {localeEN: "Kumamoto", localeRU: "Кумамото"},
	"kyoto":            {localeEN: "Kyoto", localeRU: "Киото"},
	"matsumoto":        {localeEN: "Matsumoto", localeRU: "Мацумото"},
	"matsuyama":        {localeEN: "Matsuyama", localeRU: "Мацуяма"},
	"matsushima":       {localeEN: "Matsushima", localeRU: "Мацусима"},
	"motobu":           {localeEN: "Motobu", localeRU: "Мотобу"},
	"nagakute":         {localeEN: "Nagakute", localeRU: "Нагакутэ"},
	"nagoya":           {localeEN: "Nagoya", localeRU: "Нагоя"},
	"nagasaki":         {localeEN: "Nagasaki", localeRU: "Нагасаки"},
	"naha":             {localeEN: "Naha", localeRU: "Наха"},
	"nara":             {localeEN: "Nara", localeRU: "Нара"},
	"nikko":            {localeEN: "Nikko", localeRU: "Никко"},
	"onna":             {localeEN: "Onna", localeRU: "Онна"},
	"osaka":            {localeEN: "Osaka", localeRU: "Осака"},
	"oshino":           {localeEN: "Oshino", localeRU: "Осино"},
	"otaru":            {localeEN: "Otaru", localeRU: "Отару"},
	"sapporo":          {localeEN: "Sapporo", localeRU: "Саппоро"},
	"sasebo":           {localeEN: "Sasebo", localeRU: "Сасебо"},
	"sendai":           {localeEN: "Sendai", localeRU: "Сэндай"},
	"shimizu":          {localeEN: "Shimizu", localeRU: "Симидзу"},
	"shizuoka":         {localeEN: "Shizuoka", localeRU: "Сидзуока"},
	"shirakawa-go":     {localeEN: "Shirakawa-go", localeRU: "Сиракава-го"},
	"takamatsu":        {localeEN: "Takamatsu", localeRU: "Такамацу"},
	"takayama":         {localeEN: "Takayama", localeRU: "Такаяма"},
	"tokyo":            {localeEN: "Tokyo", localeRU: "Токио"},
	"wakayama":         {localeEN: "Wakayama", localeRU: "Вакаяма"},
	"yamagata":         {localeEN: "Yamagata", localeRU: "Ямагата"},
	"yokohama":         {localeEN: "Yokohama", localeRU: "Йокогама"},
	"zao-onsen":        {localeEN: "Zao Onsen", localeRU: "Дзао-онсэн"},
	"coron":            {localeEN: "Coron", localeRU: "Корон"},
	"da-lat":           {localeEN: "Da Lat", localeRU: "Далат"},
	"da-nang":          {localeEN: "Da Nang", localeRU: "Дананг"},
	"davao":            {localeEN: "Davao", localeRU: "Давао"},
	"denpasar":         {localeEN: "Denpasar", localeRU: "Денпасар"},
	"dubai":            {localeEN: "Dubai", localeRU: "Дубай"},
	"el-nido":          {localeEN: "El Nido", localeRU: "Эль-Нидо"},
	"fujairah":         {localeEN: "Fujairah", localeRU: "Фуджейра"},
	"gilimanuk":        {localeEN: "Gilimanuk", localeRU: "Гилиманук"},
	"ha-giang":         {localeEN: "Ha Giang", localeRU: "Хазянг"},
	"ha-long":          {localeEN: "Ha Long", localeRU: "Халонг"},
	"hanoi":            {localeEN: "Hanoi", localeRU: "Ханой"},
	"ho-chi-minh-city": {localeEN: "Ho Chi Minh City", localeRU: "Хошимин"},
	"hoi-an":           {localeEN: "Hoi An", localeRU: "Хойан"},
	"hue":              {localeEN: "Hue", localeRU: "Хюэ"},
	"iloilo":           {localeEN: "Iloilo", localeRU: "Илоило"},
	"jatiluwih":        {localeEN: "Jatiluwih", localeRU: "Джатилувих"},
	"jakarta":          {localeEN: "Jakarta", localeRU: "Джакарта"},
	"jimbaran":         {localeEN: "Jimbaran", localeRU: "Джимбаран"},
	"gianyar":          {localeEN: "Gianyar", localeRU: "Гианьяр"},
	"gonio":            {localeEN: "Gonio", localeRU: "Гонио"},
	"gori":             {localeEN: "Gori", localeRU: "Гори"},
	"gudauri":          {localeEN: "Gudauri", localeRU: "Гудаури"},
	"guilin":           {localeEN: "Guilin", localeRU: "Гуйлинь"},
	"guangzhou":        {localeEN: "Guangzhou", localeRU: "Гуанчжоу"},
	"haikou":           {localeEN: "Haikou", localeRU: "Хайкоу"},
	"hainan":           {localeEN: "Hainan", localeRU: "Хайнань"},
	"hangzhou":         {localeEN: "Hangzhou", localeRU: "Ханчжоу"},
	"huangshan":        {localeEN: "Huangshan", localeRU: "Хуаншань"},
	"karaganda":        {localeEN: "Karaganda", localeRU: "Караганда"},
	"karangasem":       {localeEN: "Karangasem", localeRU: "Карангасем"},
	"hatta":            {localeEN: "Hatta", localeRU: "Хатта"},
	"khor-fakkan":      {localeEN: "Khor Fakkan", localeRU: "Хор-Факкан"},
	"kintamani":        {localeEN: "Kintamani", localeRU: "Кинтамани"},
	"kokshetau":        {localeEN: "Kokshetau", localeRU: "Кокшетау"},
	"kostanay":         {localeEN: "Kostanay", localeRU: "Костанай"},
	"keda":             {localeEN: "Keda", localeRU: "Кеда"},
	"khoni":            {localeEN: "Khoni", localeRU: "Хони"},
	"kobuleti":         {localeEN: "Kobuleti", localeRU: "Кобулети"},
	"koh-phangan":      {localeEN: "Koh Phangan", localeRU: "Панган"},
	"koh-samui":        {localeEN: "Koh Samui", localeRU: "Самуи"},
	"koh-tao":          {localeEN: "Koh Tao", localeRU: "Ко Тао"},
	"krabi":            {localeEN: "Krabi", localeRU: "Краби"},
	"kuta":             {localeEN: "Kuta", localeRU: "Кута"},
	"kutaisi":          {localeEN: "Kutaisi", localeRU: "Кутаиси"},
	"kvareli":          {localeEN: "Kvareli", localeRU: "Кварели"},
	"kvariati":         {localeEN: "Kvariati", localeRU: "Квариати"},
	"kyzylorda":        {localeEN: "Kyzylorda", localeRU: "Кызылорда"},
	"la-union":         {localeEN: "La Union", localeRU: "Ла-Унион"},
	"kaliningrad":      {localeEN: "Kaliningrad", localeRU: "Калининград"},
	"kazan":            {localeEN: "Kazan", localeRU: "Казань"},
	"legian":           {localeEN: "Legian", localeRU: "Легиан"},
	"lijiang":          {localeEN: "Lijiang", localeRU: "Лицзян"},
	"lingshui":         {localeEN: "Lingshui", localeRU: "Линшуй"},
	"luoyang":          {localeEN: "Luoyang", localeRU: "Лоян"},
	"lovina":           {localeEN: "Lovina", localeRU: "Ловина"},
	"mactan":           {localeEN: "Mactan", localeRU: "Мактан"},
	"makati":           {localeEN: "Makati", localeRU: "Макати"},
	"manila":           {localeEN: "Manila", localeRU: "Манила"},
	"martvili":         {localeEN: "Martvili", localeRU: "Мартвили"},
	"kunming":          {localeEN: "Kunming", localeRU: "Куньмин"},
	"addu-city":        {localeEN: "Addu City", localeRU: "Адду-Сити"},
	"baa-atoll":        {localeEN: "Baa Atoll", localeRU: "Атолл Баа"},
	"dharavandhoo":     {localeEN: "Dharavandhoo", localeRU: "Дхаравандху"},
	"dhiffushi":        {localeEN: "Dhiffushi", localeRU: "Диффуши"},
	"dhigurah":         {localeEN: "Dhigurah", localeRU: "Дигура"},
	"fulidhoo":         {localeEN: "Fulidhoo", localeRU: "Фулиду"},
	"fuvahmulah":       {localeEN: "Fuvahmulah", localeRU: "Фувахмулах"},
	"gan":              {localeEN: "Gan", localeRU: "Ган"},
	"gulhi":            {localeEN: "Gulhi", localeRU: "Гулхи"},
	"guraidhoo":        {localeEN: "Guraidhoo", localeRU: "Гурайду"},
	"himmafushi":       {localeEN: "Himmafushi", localeRU: "Химмафуши"},
	"hulhumale":        {localeEN: "Hulhumale", localeRU: "Хулхумале"},
	"huraa":            {localeEN: "Huraa", localeRU: "Хураа"},
	"isdhoo":           {localeEN: "Isdhoo", localeRU: "Исду"},
	"lhaviyani-atoll":  {localeEN: "Lhaviyani Atoll", localeRU: "Атолл Лавияни"},
	"maafushi":         {localeEN: "Maafushi", localeRU: "Маафуши"},
	"maamigili":        {localeEN: "Maamigili", localeRU: "Маамигили"},
	"male":             {localeEN: "Male", localeRU: "Мале"},
	"rasdhoo":          {localeEN: "Rasdhoo", localeRU: "Расду"},
	"thulusdhoo":       {localeEN: "Thulusdhoo", localeRU: "Тулусду"},
	"ukulhas":          {localeEN: "Ukulhas", localeRU: "Укулхас"},
	"utheemu":          {localeEN: "Utheemu", localeRU: "Утиму"},
	"vaadhoo":          {localeEN: "Vaadhoo", localeRU: "Ваадху"},
	"villingili":       {localeEN: "Villingili", localeRU: "Виллингили"},
	"moscow":           {localeEN: "Moscow", localeRU: "Москва"},
	"mestia":           {localeEN: "Mestia", localeRU: "Местия"},
	"mirveti":          {localeEN: "Mirveti", localeRU: "Мирвети"},
	"munduk":           {localeEN: "Munduk", localeRU: "Мундук"},
	"mtskheta":         {localeEN: "Mtskheta", localeRU: "Мцхета"},
	"mtsvane-kontskhi": {localeEN: "Mtsvane Kontskhi", localeRU: "Зеленый мыс"},
	"nha-trang":        {localeEN: "Nha Trang", localeRU: "Нячанг"},
	"nizhny-novgorod":  {localeEN: "Nizhny Novgorod", localeRU: "Нижний Новгород"},
	"ninh-binh":        {localeEN: "Ninh Binh", localeRU: "Ниньбинь"},
	"nanjing":          {localeEN: "Nanjing", localeRU: "Нанкин"},
	"nusa-dua":         {localeEN: "Nusa Dua", localeRU: "Нуса-Дуа"},
	"nusa-lembongan":   {localeEN: "Nusa Lembongan", localeRU: "Нуса-Лембонган"},
	"nusa-penida":      {localeEN: "Nusa Penida", localeRU: "Нуса-Пенида"},
	"oral":             {localeEN: "Oral", localeRU: "Орал"},
	"pavlodar":         {localeEN: "Pavlodar", localeRU: "Павлодар"},
	"beijing":          {localeEN: "Beijing", localeRU: "Пекин"},
	"danzhou":          {localeEN: "Danzhou", localeRU: "Даньчжоу"},
	"datong":           {localeEN: "Datong", localeRU: "Датун"},
	"dali":             {localeEN: "Dali", localeRU: "Дали"},
	"dengfeng":         {localeEN: "Dengfeng", localeRU: "Дэнфэн"},
	"petropavl":        {localeEN: "Petropavl", localeRU: "Петропавловск"},
	"petropavlovsk":    {localeEN: "Petropavlovsk", localeRU: "Петропавловск"},
	"pai":              {localeEN: "Pai", localeRU: "Пай"},
	"pagudpud":         {localeEN: "Pagudpud", localeRU: "Пагудпуд"},
	"phan-thiet":       {localeEN: "Phan Thiet", localeRU: "Фантхьет"},
	"phang-nga":        {localeEN: "Phang Nga", localeRU: "Пхангнга"},
	"pattaya":          {localeEN: "Pattaya", localeRU: "Паттайя"},
	"phu-quoc":         {localeEN: "Phu Quoc", localeRU: "Фукуок"},
	"phuket":           {localeEN: "Phuket", localeRU: "Пхукет"},
	"phong-nha":        {localeEN: "Phong Nha", localeRU: "Фонгня"},
	"ras-al-khaimah":   {localeEN: "Ras Al Khaimah", localeRU: "Рас-эль-Хайма"},
	"hua-hin":          {localeEN: "Hua Hin", localeRU: "Хуахин"},
	"puerto-princesa":  {localeEN: "Puerto Princesa", localeRU: "Пуэрто-Принсеса"},
	"sa-pa":            {localeEN: "Sa Pa", localeRU: "Сапа"},
	"sagada":           {localeEN: "Sagada", localeRU: "Сагада"},
	"saint-petersburg": {localeEN: "Saint Petersburg", localeRU: "Санкт-Петербург"},
	"sanur":            {localeEN: "Sanur", localeRU: "Санур"},
	"sanya":            {localeEN: "Sanya", localeRU: "Санья"},
	"semey":            {localeEN: "Semey", localeRU: "Семей"},
	"seminyak":         {localeEN: "Seminyak", localeRU: "Семиньяк"},
	"shanghai":         {localeEN: "Shanghai", localeRU: "Шанхай"},
	"sharjah":          {localeEN: "Sharjah", localeRU: "Шарджа"},
	"shenzhen":         {localeEN: "Shenzhen", localeRU: "Шэньчжэнь"},
	"sarpi":            {localeEN: "Sarpi", localeRU: "Сарпи"},
	"shymkent":         {localeEN: "Shymkent", localeRU: "Шымкент"},
	"shekvetili":       {localeEN: "Shekvetili", localeRU: "Шекветили"},
	"sighnaghi":        {localeEN: "Sighnaghi", localeRU: "Сигнахи"},
	"siargao":          {localeEN: "Siargao", localeRU: "Сиаргао"},
	"sidemen":          {localeEN: "Sidemen", localeRU: "Сидемен"},
	"suzhou":           {localeEN: "Suzhou", localeRU: "Сучжоу"},
	"xian":             {localeEN: "Xi'an", localeRU: "Сиань"},
	"xiamen":           {localeEN: "Xiamen", localeRU: "Сямэнь"},
	"singaraja":        {localeEN: "Singaraja", localeRU: "Сингараджа"},
	"sochi":            {localeEN: "Sochi", localeRU: "Сочи"},
	"stepantsminda":    {localeEN: "Stepantsminda (Kazbegi)", localeRU: "Степанцминда (Казбеги)"},
	"sukawati":         {localeEN: "Sukawati", localeRU: "Сукавати"},
	"tagaytay":         {localeEN: "Tagaytay", localeRU: "Тагайтай"},
	"taguig":           {localeEN: "Taguig", localeRU: "Тагиг"},
	"taldykorgan":      {localeEN: "Taldykorgan", localeRU: "Талдыкорган"},
	"tianjin":          {localeEN: "Tianjin", localeRU: "Тяньцзинь"},
	"qinhuangdao":      {localeEN: "Qinhuangdao", localeRU: "Циньхуандао"},
	"qionghai":         {localeEN: "Qionghai", localeRU: "Цюнхай"},
	"qingdao":          {localeEN: "Qingdao", localeRU: "Циндао"},
	"tabanan":          {localeEN: "Tabanan", localeRU: "Табанан"},
	"tampaksiring":     {localeEN: "Tampaksiring", localeRU: "Тампаксиринг"},
	"taraz":            {localeEN: "Taraz", localeRU: "Тараз"},
	"telavi":           {localeEN: "Telavi", localeRU: "Телави"},
	"tegallalang":      {localeEN: "Tegallalang", localeRU: "Тегаллаланг"},
	"terjola":          {localeEN: "Terjola", localeRU: "Тержола"},
	"tbilisi":          {localeEN: "Tbilisi", localeRU: "Тбилиси"},
	"turkestan":        {localeEN: "Turkestan", localeRU: "Туркестан"},
	"turkistan":        {localeEN: "Turkistan", localeRU: "Туркестан"},
	"tsikhisdziri":     {localeEN: "Tsikhisdziri", localeRU: "Цихисдзири"},
	"tskaltubo":        {localeEN: "Tskaltubo", localeRU: "Цхалтубо"},
	"umm-al-quwain":    {localeEN: "Umm Al Quwain", localeRU: "Умм-эль-Кувейн"},
	"ubud":             {localeEN: "Ubud", localeRU: "Убуд"},
	"uluwatu":          {localeEN: "Uluwatu", localeRU: "Улувату"},
	"uplistsikhe":      {localeEN: "Uplistsikhe", localeRU: "Уплисцихе"},
	"uralsk":           {localeEN: "Oral", localeRU: "Орал"},
	"ushguli":          {localeEN: "Ushguli", localeRU: "Ушгули"},
	"ust-kamenogorsk":  {localeEN: "Ust-Kamenogorsk", localeRU: "Усть-Каменогорск"},
	"vani":             {localeEN: "Vani", localeRU: "Вани"},
	"vardzia":          {localeEN: "Vardzia", localeRU: "Вардзия"},
	"vladivostok":      {localeEN: "Vladivostok", localeRU: "Владивосток"},
	"volgograd":        {localeEN: "Volgograd", localeRU: "Волгоград"},
	"vung-tau":         {localeEN: "Vung Tau", localeRU: "Вунгтау"},
	"vigan":            {localeEN: "Vigan", localeRU: "Виган"},
	"wanning":          {localeEN: "Wanning", localeRU: "Ваньнин"},
	"wenchang":         {localeEN: "Wenchang", localeRU: "Вэньчан"},
	"xinzhou":          {localeEN: "Xinzhou", localeRU: "Синьчжоу"},
	"yangshuo":         {localeEN: "Yangshuo", localeRU: "Яншо"},
	"yekaterinburg":    {localeEN: "Yekaterinburg", localeRU: "Екатеринбург"},
	"zhangjiajie":      {localeEN: "Zhangjiajie", localeRU: "Чжанцзяцзе"},
	"alaverdi":         {localeEN: "Alaverdi", localeRU: "Алаверди"},
	"areni":            {localeEN: "Areni", localeRU: "Арени"},
	"artanish":         {localeEN: "Artanish", localeRU: "Артаниш"},
	"ashtarak":         {localeEN: "Ashtarak", localeRU: "Аштарак"},
	"byurakan":         {localeEN: "Byurakan", localeRU: "Бюракан"},
	"dilijan":          {localeEN: "Dilijan", localeRU: "Дилижан"},
	"garni":            {localeEN: "Garni", localeRU: "Гарни"},
	"gavar":            {localeEN: "Gavar", localeRU: "Гавар"},
	"geghard":          {localeEN: "Geghard", localeRU: "Гегард"},
	"goris":            {localeEN: "Goris", localeRU: "Горис"},
	"gosh":             {localeEN: "Gosh", localeRU: "Гош"},
	"gyumri":           {localeEN: "Gyumri", localeRU: "Гюмри"},
	"haghartsin":       {localeEN: "Haghartsin", localeRU: "Агарцин"},
	"ijevan":           {localeEN: "Ijevan", localeRU: "Иджеван"},
	"jermuk":           {localeEN: "Jermuk", localeRU: "Джермук"},
	"kapan":            {localeEN: "Kapan", localeRU: "Капан"},
	"khndzoresk":       {localeEN: "Khndzoresk", localeRU: "Хндзореск"},
	"meghri":           {localeEN: "Meghri", localeRU: "Мегри"},
	"noratus":          {localeEN: "Noratus", localeRU: "Норатус"},
	"odzun":            {localeEN: "Odzun", localeRU: "Одзун"},
	"sevan":            {localeEN: "Sevan", localeRU: "Севан"},
	"shorzha":          {localeEN: "Shorzha", localeRU: "Шоржа"},
	"stepanavan":       {localeEN: "Stepanavan", localeRU: "Степанаван"},
	"tatev":            {localeEN: "Tatev", localeRU: "Татев"},
	"tsaghkadzor":      {localeEN: "Tsaghkadzor", localeRU: "Цахкадзор"},
	"vagharshapat":     {localeEN: "Vagharshapat (Echmiadzin)", localeRU: "Вагаршапат (Эчмиадзин)"},
	"vanadzor":         {localeEN: "Vanadzor", localeRU: "Ванадзор"},
	"yenokavan":        {localeEN: "Yenokavan", localeRU: "Енокаван"},
	"yerevan":          {localeEN: "Yerevan", localeRU: "Ереван"},
	"zhezkazgan":       {localeEN: "Zhezkazgan", localeRU: "Жезказган"},
}

var malaysiaCityNames = map[string]map[string]string{
	"cameron-highlands":  {localeEN: "Cameron Highlands", localeRU: "Камерон-Хайлендс"},
	"desaru":             {localeEN: "Desaru", localeRU: "Десару"},
	"george-town":        {localeEN: "George Town", localeRU: "Джорджтаун"},
	"ipoh":               {localeEN: "Ipoh", localeRU: "Ипох"},
	"johor-bahru":        {localeEN: "Johor Bahru", localeRU: "Джохор-Бару"},
	"kota-kinabalu":      {localeEN: "Kota Kinabalu", localeRU: "Кота-Кинабалу"},
	"kuala-lumpur":       {localeEN: "Kuala Lumpur", localeRU: "Куала-Лумпур"},
	"kuala-terengganu":   {localeEN: "Kuala Terengganu", localeRU: "Куала-Теренггану"},
	"kuantan":            {localeEN: "Kuantan", localeRU: "Куантан"},
	"kuching":            {localeEN: "Kuching", localeRU: "Кучинг"},
	"langkawi":           {localeEN: "Langkawi", localeRU: "Лангкави"},
	"melaka":             {localeEN: "Melaka", localeRU: "Малакка"},
	"miri":               {localeEN: "Miri", localeRU: "Мири"},
	"penang":             {localeEN: "Penang", localeRU: "Пенанг"},
	"perhentian-islands": {localeEN: "Perhentian Islands", localeRU: "Перхентианские острова"},
	"putrajaya":          {localeEN: "Putrajaya", localeRU: "Путраджая"},
	"redang":             {localeEN: "Redang", localeRU: "Реданг"},
	"sandakan":           {localeEN: "Sandakan", localeRU: "Сандакан"},
	"selangor":           {localeEN: "Selangor", localeRU: "Селангор"},
	"semporna":           {localeEN: "Semporna", localeRU: "Семпорна"},
	"tioman":             {localeEN: "Tioman", localeRU: "Тиоман"},
}

var sriLankaCityNames = map[string]map[string]string{
	"adams-peak":    {localeEN: "Adam's Peak", localeRU: "Пик Адама"},
	"anuradhapura":  {localeEN: "Anuradhapura", localeRU: "Анурадхапура"},
	"arugam-bay":    {localeEN: "Arugam Bay", localeRU: "Аругам-Бей"},
	"bentota":       {localeEN: "Bentota", localeRU: "Бентота"},
	"colombo":       {localeEN: "Colombo", localeRU: "Коломбо"},
	"dambulla":      {localeEN: "Dambulla", localeRU: "Дамбулла"},
	"ella":          {localeEN: "Ella", localeRU: "Элла"},
	"galle":         {localeEN: "Galle", localeRU: "Галле"},
	"haputale":      {localeEN: "Haputale", localeRU: "Хапутале"},
	"hikkaduwa":     {localeEN: "Hikkaduwa", localeRU: "Хиккадува"},
	"jaffna":        {localeEN: "Jaffna", localeRU: "Джафна"},
	"kandy":         {localeEN: "Kandy", localeRU: "Канди"},
	"mirissa":       {localeEN: "Mirissa", localeRU: "Мирисса"},
	"mount-lavinia": {localeEN: "Mount Lavinia", localeRU: "Маунт-Лавиния"},
	"negombo":       {localeEN: "Negombo", localeRU: "Негомбо"},
	"nuwara-eliya":  {localeEN: "Nuwara Eliya", localeRU: "Нувара-Элия"},
	"polonnaruwa":   {localeEN: "Polonnaruwa", localeRU: "Полоннарува"},
	"sigiriya":      {localeEN: "Sigiriya", localeRU: "Сигирия"},
	"trincomalee":   {localeEN: "Trincomalee", localeRU: "Тринкомали"},
	"udawalawe":     {localeEN: "Udawalawe", localeRU: "Удавалаве"},
	"unawatuna":     {localeEN: "Unawatuna", localeRU: "Унаватуна"},
	"wilpattu":      {localeEN: "Wilpattu", localeRU: "Вилпатту"},
	"yala":          {localeEN: "Yala", localeRU: "Яла"},
}

var montenegroCityNames = map[string]map[string]string{
	"ada-bojana":      {localeEN: "Ada Bojana", localeRU: "Ада-Бояна"},
	"bar":             {localeEN: "Bar", localeRU: "Бар"},
	"becici":          {localeEN: "Becici", localeRU: "Бечичи"},
	"biogradska-gora": {localeEN: "Biogradska Gora", localeRU: "Биоградская гора"},
	"budva":           {localeEN: "Budva", localeRU: "Будва"},
	"cetinje":         {localeEN: "Cetinje", localeRU: "Цетине"},
	"durmitor":        {localeEN: "Durmitor", localeRU: "Дурмитор"},
	"gusinje":         {localeEN: "Gusinje", localeRU: "Гусине"},
	"herceg-novi":     {localeEN: "Herceg Novi", localeRU: "Херцег-Нови"},
	"kolasin":         {localeEN: "Kolasin", localeRU: "Колашин"},
	"kotor":           {localeEN: "Kotor", localeRU: "Котор"},
	"lovcen":          {localeEN: "Lovcen", localeRU: "Ловчен"},
	"niksic":          {localeEN: "Niksic", localeRU: "Никшич"},
	"ostrog":          {localeEN: "Ostrog", localeRU: "Острог"},
	"perast":          {localeEN: "Perast", localeRU: "Пераст"},
	"petrovac":        {localeEN: "Petrovac", localeRU: "Петровац"},
	"plav":            {localeEN: "Plav", localeRU: "Плав"},
	"podgorica":       {localeEN: "Podgorica", localeRU: "Подгорица"},
	"risan":           {localeEN: "Risan", localeRU: "Рисан"},
	"sveti-stefan":    {localeEN: "Sveti Stefan", localeRU: "Свети-Стефан"},
	"tivat":           {localeEN: "Tivat", localeRU: "Тиват"},
	"ulcinj":          {localeEN: "Ulcinj", localeRU: "Ульцинь"},
	"virpazar":        {localeEN: "Virpazar", localeRU: "Вирпазар"},
	"zabljak":         {localeEN: "Zabljak", localeRU: "Жабляк"},
}

var indiaCityNames = map[string]map[string]string{
	"agra":       {localeEN: "Agra", localeRU: "Агра"},
	"ahmedabad":  {localeEN: "Ahmedabad", localeRU: "Ахмадабад"},
	"alappuzha":  {localeEN: "Alappuzha", localeRU: "Алаппужа"},
	"amritsar":   {localeEN: "Amritsar", localeRU: "Амритсар"},
	"bengaluru":  {localeEN: "Bengaluru", localeRU: "Бенгалуру"},
	"chennai":    {localeEN: "Chennai", localeRU: "Ченнаи"},
	"darjeeling": {localeEN: "Darjeeling", localeRU: "Дарджилинг"},
	"delhi":      {localeEN: "Delhi", localeRU: "Дели"},
	"gangtok":    {localeEN: "Gangtok", localeRU: "Гангток"},
	"goa":        {localeEN: "Goa", localeRU: "Гоа"},
	"guwahati":   {localeEN: "Guwahati", localeRU: "Гувахати"},
	"hampi":      {localeEN: "Hampi", localeRU: "Хампи"},
	"haridwar":   {localeEN: "Haridwar", localeRU: "Харидвар"},
	"hyderabad":  {localeEN: "Hyderabad", localeRU: "Хайдарабад"},
	"jaipur":     {localeEN: "Jaipur", localeRU: "Джайпур"},
	"jodhpur":    {localeEN: "Jodhpur", localeRU: "Джодхпур"},
	"kochi":      {localeEN: "Kochi", localeRU: "Кочи"},
	"kolkata":    {localeEN: "Kolkata", localeRU: "Калькутта"},
	"kovalam":    {localeEN: "Kovalam", localeRU: "Ковалам"},
	"leh":        {localeEN: "Leh", localeRU: "Лех"},
	"manali":     {localeEN: "Manali", localeRU: "Манали"},
	"mumbai":     {localeEN: "Mumbai", localeRU: "Мумбаи"},
	"munnar":     {localeEN: "Munnar", localeRU: "Муннар"},
	"mysuru":     {localeEN: "Mysuru", localeRU: "Майсур"},
	"pune":       {localeEN: "Pune", localeRU: "Пуна"},
	"rishikesh":  {localeEN: "Rishikesh", localeRU: "Ришикеш"},
	"shillong":   {localeEN: "Shillong", localeRU: "Шиллонг"},
	"udaipur":    {localeEN: "Udaipur", localeRU: "Удайпур"},
	"varanasi":   {localeEN: "Varanasi", localeRU: "Варанаси"},
}

var maltaCityNames = map[string]map[string]string{
	"attard":        {localeEN: "Attard", localeRU: "Аттард"},
	"birgu":         {localeEN: "Birgu", localeRU: "Биргу"},
	"birzebbuga":    {localeEN: "Birzebbuga", localeRU: "Бирзеббуджа"},
	"comino":        {localeEN: "Comino", localeRU: "Комино"},
	"dingli":        {localeEN: "Dingli", localeRU: "Дингли"},
	"gozo":          {localeEN: "Gozo", localeRU: "Гозо"},
	"marsalforn":    {localeEN: "Marsalforn", localeRU: "Марсалфорн"},
	"marsaxlokk":    {localeEN: "Marsaxlokk", localeRU: "Марсашлокк"},
	"mdina":         {localeEN: "Mdina", localeRU: "Мдина"},
	"mellieha":      {localeEN: "Mellieha", localeRU: "Меллиха"},
	"mosta":         {localeEN: "Mosta", localeRU: "Моста"},
	"paola":         {localeEN: "Paola", localeRU: "Паола"},
	"qrendi":        {localeEN: "Qrendi", localeRU: "Кренди"},
	"rabat-malta":   {localeEN: "Rabat", localeRU: "Рабат"},
	"sliema":        {localeEN: "Sliema", localeRU: "Слима"},
	"st-julians":    {localeEN: "St Julian's", localeRU: "Сент-Джулианс"},
	"st-pauls-bay":  {localeEN: "St Paul's Bay", localeRU: "Сент-Полс-Бей"},
	"ta-qali":       {localeEN: "Ta' Qali", localeRU: "Та-Кали"},
	"tarxien":       {localeEN: "Tarxien", localeRU: "Таршиен"},
	"valletta":      {localeEN: "Valletta", localeRU: "Валлетта"},
	"victoria-gozo": {localeEN: "Victoria (Gozo)", localeRU: "Виктория (Гозо)"},
	"xaghra":        {localeEN: "Xaghra", localeRU: "Шаара"},
	"xlendi":        {localeEN: "Xlendi", localeRU: "Шленди"},
}

var cyprusCityNames = map[string]map[string]string{
	"agros":        {localeEN: "Agros", localeRU: "Агрос"},
	"ayia-napa":    {localeEN: "Ayia Napa", localeRU: "Айя-Напа"},
	"choirokoitia": {localeEN: "Choirokoitia", localeRU: "Хирокития"},
	"coral-bay":    {localeEN: "Coral Bay", localeRU: "Корал-Бэй"},
	"famagusta":    {localeEN: "Famagusta", localeRU: "Фамагуста"},
	"kakopetria":   {localeEN: "Kakopetria", localeRU: "Какопетрия"},
	"kourion":      {localeEN: "Kourion", localeRU: "Курион"},
	"kyrenia":      {localeEN: "Kyrenia", localeRU: "Кирения"},
	"larnaca":      {localeEN: "Larnaca", localeRU: "Ларнака"},
	"latchi":       {localeEN: "Latchi", localeRU: "Лачи"},
	"limassol":     {localeEN: "Limassol", localeRU: "Лимасол"},
	"nicosia":      {localeEN: "Nicosia", localeRU: "Никосия"},
	"omodos":       {localeEN: "Omodos", localeRU: "Омодос"},
	"paphos":       {localeEN: "Paphos", localeRU: "Пафос"},
	"paralimni":    {localeEN: "Paralimni", localeRU: "Паралимни"},
	"peyia":        {localeEN: "Peyia", localeRU: "Пейя"},
	"platres":      {localeEN: "Platres", localeRU: "Платрес"},
	"polis":        {localeEN: "Polis", localeRU: "Полис"},
	"protaras":     {localeEN: "Protaras", localeRU: "Протарас"},
	"troodos":      {localeEN: "Troodos", localeRU: "Троодос"},
}

var seychellesCityNames = map[string]map[string]string{
	"anse-reunion":       {localeEN: "Anse Reunion", localeRU: "Анс-Реюньон"},
	"anse-royale":        {localeEN: "Anse Royale", localeRU: "Анс-Руаяль"},
	"baie-sainte-anne":   {localeEN: "Baie Sainte Anne", localeRU: "Бэ-Сент-Анн"},
	"beau-vallon":        {localeEN: "Beau Vallon", localeRU: "Бо-Валлон"},
	"cerf-island":        {localeEN: "Cerf Island", localeRU: "Остров Серф"},
	"cousin-island":      {localeEN: "Cousin Island", localeRU: "Остров Кузен"},
	"curieuse-island":    {localeEN: "Curieuse Island", localeRU: "Остров Кюрьёз"},
	"eden-island":        {localeEN: "Eden Island", localeRU: "Иден-Айленд"},
	"felicite-island":    {localeEN: "Felicite Island", localeRU: "Остров Фелисите"},
	"grand-anse-praslin": {localeEN: "Grand Anse Praslin", localeRU: "Гранд-Анс Праслин"},
	"ile-cocos":          {localeEN: "Ile Cocos", localeRU: "Иль-Кокос"},
	"la-digue":           {localeEN: "La Digue", localeRU: "Ла-Диг"},
	"la-passe":           {localeEN: "La Passe", localeRU: "Ла-Пасс"},
	"mahe":               {localeEN: "Mahe", localeRU: "Маэ"},
	"moyenne-island":     {localeEN: "Moyenne Island", localeRU: "Остров Муаен"},
	"port-glaud":         {localeEN: "Port Glaud", localeRU: "Порт-Гло"},
	"praslin":            {localeEN: "Praslin", localeRU: "Праслин"},
	"sainte-anne-island": {localeEN: "Sainte Anne Island", localeRU: "Остров Сент-Анн"},
	"silhouette-island":  {localeEN: "Silhouette Island", localeRU: "Остров Силуэт"},
	"takamaka":           {localeEN: "Takamaka", localeRU: "Такамака"},
	"victoria":           {localeEN: "Victoria", localeRU: "Виктория"},
}

var polandCityNames = map[string]map[string]string{
	"bialowieza":  {localeEN: "Bialowieza", localeRU: "Беловежа"},
	"bialystok":   {localeEN: "Bialystok", localeRU: "Белосток"},
	"chorzow":     {localeEN: "Chorzow", localeRU: "Хожув"},
	"czestochowa": {localeEN: "Czestochowa", localeRU: "Ченстохова"},
	"gdansk":      {localeEN: "Gdansk", localeRU: "Гданьск"},
	"gdynia":      {localeEN: "Gdynia", localeRU: "Гдыня"},
	"katowice":    {localeEN: "Katowice", localeRU: "Катовице"},
	"krakow":      {localeEN: "Krakow", localeRU: "Краков"},
	"lodz":        {localeEN: "Lodz", localeRU: "Лодзь"},
	"lublin":      {localeEN: "Lublin", localeRU: "Люблин"},
	"malbork":     {localeEN: "Malbork", localeRU: "Мальборк"},
	"oswiecim":    {localeEN: "Oswiecim", localeRU: "Освенцим"},
	"poznan":      {localeEN: "Poznan", localeRU: "Познань"},
	"sopot":       {localeEN: "Sopot", localeRU: "Сопот"},
	"szczecin":    {localeEN: "Szczecin", localeRU: "Щецин"},
	"torun":       {localeEN: "Torun", localeRU: "Торунь"},
	"warsaw":      {localeEN: "Warsaw", localeRU: "Варшава"},
	"wieliczka":   {localeEN: "Wieliczka", localeRU: "Величка"},
	"wroclaw":     {localeEN: "Wroclaw", localeRU: "Вроцлав"},
	"zakopane":    {localeEN: "Zakopane", localeRU: "Закопане"},
	"zamosc":      {localeEN: "Zamosc", localeRU: "Замосць"},
}

var mexicoCityNames = map[string]map[string]string{
	"acapulco":                   {localeEN: "Acapulco", localeRU: "Акапулько"},
	"cabo-san-lucas":             {localeEN: "Cabo San Lucas", localeRU: "Кабо-Сан-Лукас"},
	"cancun":                     {localeEN: "Cancun", localeRU: "Канкун"},
	"chichen-itza":               {localeEN: "Chichen Itza", localeRU: "Чичен-Ица"},
	"cholula":                    {localeEN: "Cholula", localeRU: "Чолула"},
	"cozumel":                    {localeEN: "Cozumel", localeRU: "Косумель"},
	"cuernavaca":                 {localeEN: "Cuernavaca", localeRU: "Куэрнавака"},
	"guanajuato":                 {localeEN: "Guanajuato", localeRU: "Гуанахуато"},
	"guadalajara":                {localeEN: "Guadalajara", localeRU: "Гвадалахара"},
	"isla-mujeres":               {localeEN: "Isla Mujeres", localeRU: "Исла-Мухерес"},
	"la-paz-mexico":              {localeEN: "La Paz", localeRU: "Ла-Пас"},
	"los-cabos":                  {localeEN: "Los Cabos", localeRU: "Лос-Кабос"},
	"mazatlan":                   {localeEN: "Mazatlan", localeRU: "Масатлан"},
	"merida":                     {localeEN: "Merida", localeRU: "Мерида"},
	"mexico-city":                {localeEN: "Mexico City", localeRU: "Мехико"},
	"monte-alban":                {localeEN: "Monte Alban", localeRU: "Монте-Альбан"},
	"monterrey":                  {localeEN: "Monterrey", localeRU: "Монтеррей"},
	"oaxaca":                     {localeEN: "Oaxaca", localeRU: "Оахака"},
	"palenque":                   {localeEN: "Palenque", localeRU: "Паленке"},
	"playa-del-carmen":           {localeEN: "Playa del Carmen", localeRU: "Плая-дель-Кармен"},
	"puebla":                     {localeEN: "Puebla", localeRU: "Пуэбла"},
	"puerto-vallarta":            {localeEN: "Puerto Vallarta", localeRU: "Пуэрто-Вальярта"},
	"queretaro":                  {localeEN: "Queretaro", localeRU: "Керетаро"},
	"san-cristobal-de-las-casas": {localeEN: "San Cristobal de las Casas", localeRU: "Сан-Кристобаль-де-лас-Касас"},
	"san-jose-del-cabo":          {localeEN: "San Jose del Cabo", localeRU: "Сан-Хосе-дель-Кабо"},
	"san-miguel-de-allende":      {localeEN: "San Miguel de Allende", localeRU: "Сан-Мигель-де-Альенде"},
	"sayulita":                   {localeEN: "Sayulita", localeRU: "Саюлита"},
	"teotihuacan":                {localeEN: "Teotihuacan", localeRU: "Теотиуакан"},
	"tequila":                    {localeEN: "Tequila", localeRU: "Текила"},
	"tulum":                      {localeEN: "Tulum", localeRU: "Тулум"},
	"uxmal":                      {localeEN: "Uxmal", localeRU: "Ушмаль"},
	"valladolid":                 {localeEN: "Valladolid", localeRU: "Вальядолид"},
	"zihuatanejo":                {localeEN: "Zihuatanejo", localeRU: "Сиуатанехо"},
}

var brazilCityNames = map[string]map[string]string{
	"angra-dos-reis":        {localeEN: "Angra dos Reis", localeRU: "Ангра-дус-Рейс"},
	"belem":                 {localeEN: "Belem", localeRU: "Белен"},
	"belo-horizonte":        {localeEN: "Belo Horizonte", localeRU: "Белу-Оризонти"},
	"bonito":                {localeEN: "Bonito", localeRU: "Бонито"},
	"brasilia":              {localeEN: "Brasilia", localeRU: "Бразилиа"},
	"buzios":                {localeEN: "Buzios", localeRU: "Бузиос"},
	"chapada-dos-veadeiros": {localeEN: "Chapada dos Veadeiros", localeRU: "Шапада-дус-Веадейрус"},
	"cuiaba":                {localeEN: "Cuiaba", localeRU: "Куяба"},
	"curitiba":              {localeEN: "Curitiba", localeRU: "Куритиба"},
	"florianopolis":         {localeEN: "Florianopolis", localeRU: "Флорианополис"},
	"fortaleza":             {localeEN: "Fortaleza", localeRU: "Форталеза"},
	"foz-do-iguacu":         {localeEN: "Foz do Iguacu", localeRU: "Фос-ду-Игуасу"},
	"gramado":               {localeEN: "Gramado", localeRU: "Грамаду"},
	"jericoacoara":          {localeEN: "Jericoacoara", localeRU: "Жерикоакоара"},
	"lencois-maranhenses":   {localeEN: "Lencois Maranhenses", localeRU: "Ленсойс-Мараньенсис"},
	"manaus":                {localeEN: "Manaus", localeRU: "Манаус"},
	"natal":                 {localeEN: "Natal", localeRU: "Натал"},
	"olinda":                {localeEN: "Olinda", localeRU: "Олинда"},
	"ouro-preto":            {localeEN: "Ouro Preto", localeRU: "Ору-Прету"},
	"pantanal":              {localeEN: "Pantanal", localeRU: "Пантанал"},
	"paraty":                {localeEN: "Paraty", localeRU: "Парати"},
	"petropolis":            {localeEN: "Petropolis", localeRU: "Петрополис"},
	"pipa":                  {localeEN: "Pipa", localeRU: "Пипа"},
	"porto-alegre":          {localeEN: "Porto Alegre", localeRU: "Порту-Алегри"},
	"porto-de-galinhas":     {localeEN: "Porto de Galinhas", localeRU: "Порту-де-Галиньяс"},
	"recife":                {localeEN: "Recife", localeRU: "Ресифи"},
	"rio-de-janeiro":        {localeEN: "Rio de Janeiro", localeRU: "Рио-де-Жанейро"},
	"salvador":              {localeEN: "Salvador", localeRU: "Салвадор"},
	"santos":                {localeEN: "Santos", localeRU: "Сантус"},
	"sao-luis":              {localeEN: "Sao Luis", localeRU: "Сан-Луис"},
	"sao-paulo":             {localeEN: "Sao Paulo", localeRU: "Сан-Паулу"},
}

var abkhaziaCityNames = map[string]map[string]string{
	"gagra":      {localeEN: "Gagra", localeRU: "Гагра"},
	"gali":       {localeEN: "Gali", localeRU: "Гал"},
	"gudauta":    {localeEN: "Gudauta", localeRU: "Гудаута"},
	"lake-ritsa": {localeEN: "Lake Ritsa", localeRU: "Озеро Рица"},
	"new-athos":  {localeEN: "New Athos", localeRU: "Новый Афон"},
	"ochamchira": {localeEN: "Ochamchira", localeRU: "Очамчира"},
	"otap":       {localeEN: "Otap", localeRU: "Отап"},
	"pitsunda":   {localeEN: "Pitsunda", localeRU: "Пицунда"},
	"sukhum":     {localeEN: "Sukhum", localeRU: "Сухум"},
	"tkvarcheli": {localeEN: "Tkvarcheli", localeRU: "Ткуарчал"},
}

var cubaCityNames = map[string]map[string]string{
	"baracoa":          {localeEN: "Baracoa", localeRU: "Баракоа"},
	"camaguey":         {localeEN: "Camaguey", localeRU: "Камагуэй"},
	"cayo-coco":        {localeEN: "Cayo Coco", localeRU: "Кайо-Коко"},
	"cayo-guillermo":   {localeEN: "Cayo Guillermo", localeRU: "Кайо-Гильермо"},
	"cayo-santa-maria": {localeEN: "Cayo Santa Maria", localeRU: "Кайо-Санта-Мария"},
	"cienfuegos":       {localeEN: "Cienfuegos", localeRU: "Сьенфуэгос"},
	"guardalavaca":     {localeEN: "Guardalavaca", localeRU: "Гуардалавака"},
	"havana":           {localeEN: "Havana", localeRU: "Гавана"},
	"holguin":          {localeEN: "Holguin", localeRU: "Ольгин"},
	"matanzas":         {localeEN: "Matanzas", localeRU: "Матансас"},
	"playa-larga":      {localeEN: "Playa Larga", localeRU: "Плая-Ларга"},
	"santa-clara":      {localeEN: "Santa Clara", localeRU: "Санта-Клара"},
	"santiago-de-cuba": {localeEN: "Santiago de Cuba", localeRU: "Сантьяго-де-Куба"},
	"trinidad":         {localeEN: "Trinidad", localeRU: "Тринидад"},
	"varadero":         {localeEN: "Varadero", localeRU: "Варадеро"},
	"vinales":          {localeEN: "Vinales", localeRU: "Виньялес"},
}

var moroccoCityNames = map[string]map[string]string{
	"agadir":           {localeEN: "Agadir", localeRU: "Агадир"},
	"agafay":           {localeEN: "Agafay", localeRU: "Агафай"},
	"asilah":           {localeEN: "Asilah", localeRU: "Асила"},
	"azilal":           {localeEN: "Azilal", localeRU: "Азилаль"},
	"casablanca":       {localeEN: "Casablanca", localeRU: "Касабланка"},
	"chefchaouen":      {localeEN: "Chefchaouen", localeRU: "Шефшауэн"},
	"essaouira":        {localeEN: "Essaouira", localeRU: "Эс-Сувейра"},
	"fes":              {localeEN: "Fes", localeRU: "Фес"},
	"ifrane":           {localeEN: "Ifrane", localeRU: "Ифран"},
	"imlil":            {localeEN: "Imlil", localeRU: "Имлиль"},
	"lalla-takerkoust": {localeEN: "Lalla Takerkoust", localeRU: "Лалла-Такеркуст"},
	"marrakech":        {localeEN: "Marrakech", localeRU: "Марракеш"},
	"meknes":           {localeEN: "Meknes", localeRU: "Мекнес"},
	"merzouga":         {localeEN: "Merzouga", localeRU: "Мерзуга"},
	"ouarzazate":       {localeEN: "Ouarzazate", localeRU: "Уарзазат"},
	"ourika":           {localeEN: "Ourika", localeRU: "Урика"},
	"ouzoud":           {localeEN: "Ouzoud", localeRU: "Узуд"},
	"rabat":            {localeEN: "Rabat", localeRU: "Рабат"},
	"taghazout":        {localeEN: "Taghazout", localeRU: "Тагазут"},
	"tangier":          {localeEN: "Tangier", localeRU: "Танжер"},
	"tetouan":          {localeEN: "Tetouan", localeRU: "Тетуан"},
	"volubilis":        {localeEN: "Volubilis", localeRU: "Волюбилис"},
}

var portugalCityNames = map[string]map[string]string{
	"albufeira":         {localeEN: "Albufeira", localeRU: "Албуфейра"},
	"aveiro":            {localeEN: "Aveiro", localeRU: "Авейру"},
	"braga":             {localeEN: "Braga", localeRU: "Брага"},
	"cascais":           {localeEN: "Cascais", localeRU: "Кашкайш"},
	"coimbra":           {localeEN: "Coimbra", localeRU: "Коимбра"},
	"douro-valley":      {localeEN: "Douro Valley", localeRU: "Долина Дору"},
	"evora":             {localeEN: "Evora", localeRU: "Эвора"},
	"faro":              {localeEN: "Faro", localeRU: "Фару"},
	"fatima":            {localeEN: "Fatima", localeRU: "Фатима"},
	"funchal":           {localeEN: "Funchal", localeRU: "Фуншал"},
	"guimaraes":         {localeEN: "Guimaraes", localeRU: "Гимарайнш"},
	"alcobaca":          {localeEN: "Alcobaca", localeRU: "Алкобаса"},
	"lagoa":             {localeEN: "Lagoa", localeRU: "Лагоа"},
	"lagos":             {localeEN: "Lagos", localeRU: "Лагуш"},
	"lisbon":            {localeEN: "Lisbon", localeRU: "Лиссабон"},
	"batalha":           {localeEN: "Batalha", localeRU: "Баталья"},
	"berlengas":         {localeEN: "Berlengas", localeRU: "Берленгаш"},
	"carvoeiro":         {localeEN: "Carvoeiro", localeRU: "Карвоэйру"},
	"comporta":          {localeEN: "Comporta", localeRU: "Компорта"},
	"faial":             {localeEN: "Faial", localeRU: "Фаял"},
	"madeira":           {localeEN: "Madeira", localeRU: "Мадейра"},
	"nazare":            {localeEN: "Nazare", localeRU: "Назаре"},
	"obidos":            {localeEN: "Obidos", localeRU: "Обидуш"},
	"loule":             {localeEN: "Loule", localeRU: "Лоле"},
	"monsaraz":          {localeEN: "Monsaraz", localeRU: "Монсараш"},
	"peneda-geres":      {localeEN: "Peneda-Geres", localeRU: "Пенеда-Жереш"},
	"peniche":           {localeEN: "Peniche", localeRU: "Пениши"},
	"pico":              {localeEN: "Pico", localeRU: "Пику"},
	"ponta-delgada":     {localeEN: "Ponta Delgada", localeRU: "Понта-Делгада"},
	"portimao":          {localeEN: "Portimao", localeRU: "Портиман"},
	"porto":             {localeEN: "Porto", localeRU: "Порту"},
	"porto-santo":       {localeEN: "Porto Santo", localeRU: "Порту-Санту"},
	"sagres":            {localeEN: "Sagres", localeRU: "Сагреш"},
	"sao-miguel":        {localeEN: "Sao Miguel", localeRU: "Сан-Мигел"},
	"serra-da-estrela":  {localeEN: "Serra da Estrela", localeRU: "Серра-да-Эштрела"},
	"sesimbra":          {localeEN: "Sesimbra", localeRU: "Сезимбра"},
	"setubal":           {localeEN: "Setubal", localeRU: "Сетубал"},
	"sintra":            {localeEN: "Sintra", localeRU: "Синтра"},
	"tavira":            {localeEN: "Tavira", localeRU: "Тавира"},
	"terceira":          {localeEN: "Terceira", localeRU: "Терсейра"},
	"tomar":             {localeEN: "Tomar", localeRU: "Томар"},
	"viana-do-castelo":  {localeEN: "Viana do Castelo", localeRU: "Виана-ду-Каштелу"},
	"vila-nova-de-gaia": {localeEN: "Vila Nova de Gaia", localeRU: "Вила-Нова-де-Гая"},
	"vilamoura":         {localeEN: "Vilamoura", localeRU: "Виламора"},
}

var italyCityNames = map[string]map[string]string{
	"agrigento":         {localeEN: "Agrigento", localeRU: "Агридженто"},
	"alberobello":       {localeEN: "Alberobello", localeRU: "Альберобелло"},
	"amalfi-coast":      {localeEN: "Amalfi Coast", localeRU: "Амальфитанское побережье"},
	"andria":            {localeEN: "Andria", localeRU: "Андрия"},
	"bari":              {localeEN: "Bari", localeRU: "Бари"},
	"barumini":          {localeEN: "Barumini", localeRU: "Барумини"},
	"baunei":            {localeEN: "Baunei", localeRU: "Баунеи"},
	"cagliari":          {localeEN: "Cagliari", localeRU: "Кальяри"},
	"capri":             {localeEN: "Capri", localeRU: "Капри"},
	"castellana-grotte": {localeEN: "Castellana Grotte", localeRU: "Кастеллана-Гротте"},
	"castelli-romani":   {localeEN: "Castelli Romani", localeRU: "Кастелли-Романи"},
	"catania":           {localeEN: "Catania", localeRU: "Катания"},
	"costa-smeralda":    {localeEN: "Costa Smeralda", localeRU: "Коста-Смеральда"},
	"florence":          {localeEN: "Florence", localeRU: "Флоренция"},
	"lake-como":         {localeEN: "Lake Como", localeRU: "Озеро Комо"},
	"lake-garda":        {localeEN: "Lake Garda", localeRU: "Озеро Гарда"},
	"la-maddalena":      {localeEN: "La Maddalena", localeRU: "Ла-Маддалена"},
	"lazio-coast":       {localeEN: "Lazio Coast", localeRU: "Побережье Лацио"},
	"lucca":             {localeEN: "Lucca", localeRU: "Лукка"},
	"matera":            {localeEN: "Matera", localeRU: "Матера"},
	"milan":             {localeEN: "Milan", localeRU: "Милан"},
	"mount-vesuvius":    {localeEN: "Mount Vesuvius", localeRU: "Везувий"},
	"naples":            {localeEN: "Naples", localeRU: "Неаполь"},
	"ostia":             {localeEN: "Ostia", localeRU: "Остия"},
	"palermo":           {localeEN: "Palermo", localeRU: "Палермо"},
	"pisa":              {localeEN: "Pisa", localeRU: "Пиза"},
	"polignano-a-mare":  {localeEN: "Polignano a Mare", localeRU: "Полиньяно-а-Маре"},
	"pollino":           {localeEN: "Pollino", localeRU: "Поллино"},
	"pompeii":           {localeEN: "Pompeii", localeRU: "Помпеи"},
	"reggio-calabria":   {localeEN: "Reggio Calabria", localeRU: "Реджо-ди-Калабрия"},
	"rome":              {localeEN: "Rome", localeRU: "Рим"},
	"sardinia":          {localeEN: "Sardinia", localeRU: "Сардиния"},
	"scilla":            {localeEN: "Scilla", localeRU: "Шилла"},
	"siena":             {localeEN: "Siena", localeRU: "Сиена"},
	"sorrento":          {localeEN: "Sorrento", localeRU: "Сорренто"},
	"tivoli":            {localeEN: "Tivoli", localeRU: "Тиволи"},
	"tropea":            {localeEN: "Tropea", localeRU: "Тропея"},
	"valmontone":        {localeEN: "Valmontone", localeRU: "Вальмонтоне"},
	"venice":            {localeEN: "Venice", localeRU: "Венеция"},
	"verona":            {localeEN: "Verona", localeRU: "Верона"},
	"zingaro":           {localeEN: "Zingaro", localeRU: "Дзингаро"},
}

var spainCityNames = map[string]map[string]string{
	"a-coruna":               {localeEN: "A Coruna", localeRU: "А-Корунья"},
	"alicante":               {localeEN: "Alicante", localeRU: "Аликанте"},
	"andalusia":              {localeEN: "Andalusia", localeRU: "Андалусия"},
	"aranjuez":               {localeEN: "Aranjuez", localeRU: "Аранхуэс"},
	"asturias":               {localeEN: "Asturias", localeRU: "Астурия"},
	"barcelona":              {localeEN: "Barcelona", localeRU: "Барселона"},
	"benidorm":               {localeEN: "Benidorm", localeRU: "Бенидорм"},
	"bilbao":                 {localeEN: "Bilbao", localeRU: "Бильбао"},
	"cadiz":                  {localeEN: "Cadiz", localeRU: "Кадис"},
	"calpe":                  {localeEN: "Calpe", localeRU: "Кальпе"},
	"cartagena":              {localeEN: "Cartagena", localeRU: "Картахена"},
	"cordoba":                {localeEN: "Cordoba", localeRU: "Кордова"},
	"costa-brava":            {localeEN: "Costa Brava", localeRU: "Коста-Брава"},
	"el-escorial":            {localeEN: "El Escorial", localeRU: "Эль-Эскориал"},
	"elche":                  {localeEN: "Elche", localeRU: "Эльче"},
	"figueres":               {localeEN: "Figueres", localeRU: "Фигерас"},
	"fuerteventura":          {localeEN: "Fuerteventura", localeRU: "Фуэртевентура"},
	"girona":                 {localeEN: "Girona", localeRU: "Жирона"},
	"gran-canaria":           {localeEN: "Gran Canaria", localeRU: "Гран-Канария"},
	"granada":                {localeEN: "Granada", localeRU: "Гранада"},
	"ibiza":                  {localeEN: "Ibiza", localeRU: "Ибица"},
	"lanzarote":              {localeEN: "Lanzarote", localeRU: "Лансароте"},
	"madrid":                 {localeEN: "Madrid", localeRU: "Мадрид"},
	"malaga":                 {localeEN: "Malaga", localeRU: "Малага"},
	"mallorca":               {localeEN: "Mallorca", localeRU: "Майорка"},
	"marbella":               {localeEN: "Marbella", localeRU: "Марбелья"},
	"menorca":                {localeEN: "Menorca", localeRU: "Менорка"},
	"montserrat":             {localeEN: "Montserrat", localeRU: "Монсеррат"},
	"murcia":                 {localeEN: "Murcia", localeRU: "Мурсия"},
	"pamplona":               {localeEN: "Pamplona", localeRU: "Памплона"},
	"ronda":                  {localeEN: "Ronda", localeRU: "Ронда"},
	"salou":                  {localeEN: "Salou", localeRU: "Салоу"},
	"san-sebastian":          {localeEN: "San Sebastian", localeRU: "Сан-Себастьян"},
	"santander":              {localeEN: "Santander", localeRU: "Сантандер"},
	"santiago-de-compostela": {localeEN: "Santiago de Compostela", localeRU: "Сантьяго-де-Компостела"},
	"segovia":                {localeEN: "Segovia", localeRU: "Сеговия"},
	"seville":                {localeEN: "Seville", localeRU: "Севилья"},
	"sierra-guadarrama":      {localeEN: "Sierra de Guadarrama", localeRU: "Сьерра-де-Гвадаррама"},
	"tarifa":                 {localeEN: "Tarifa", localeRU: "Тарифа"},
	"tenerife":               {localeEN: "Tenerife", localeRU: "Тенерифе"},
	"toledo":                 {localeEN: "Toledo", localeRU: "Толедо"},
	"valencia":               {localeEN: "Valencia", localeRU: "Валенсия"},
	"zaragoza":               {localeEN: "Zaragoza", localeRU: "Сарагоса"},
}

var luxembourgCityNames = map[string]map[string]string{
	"beaufort":          {localeEN: "Beaufort", localeRU: "Бофор"},
	"belval":            {localeEN: "Belval", localeRU: "Бельваль"},
	"berdorf":           {localeEN: "Berdorf", localeRU: "Бердорф"},
	"bourscheid":        {localeEN: "Bourscheid", localeRU: "Буршайд"},
	"clervaux":          {localeEN: "Clervaux", localeRU: "Клерво"},
	"diekirch":          {localeEN: "Diekirch", localeRU: "Дикирх"},
	"differdange":       {localeEN: "Differdange", localeRU: "Дифферданж"},
	"dudelange":         {localeEN: "Dudelange", localeRU: "Дюделанж"},
	"echternach":        {localeEN: "Echternach", localeRU: "Эхтернах"},
	"esch-sur-alzette":  {localeEN: "Esch-sur-Alzette", localeRU: "Эш-сюр-Альзетт"},
	"esch-sur-sure":     {localeEN: "Esch-sur-Sure", localeRU: "Эш-сюр-Сюр"},
	"ettelbruck":        {localeEN: "Ettelbruck", localeRU: "Эттельбрюк"},
	"grevenmacher":      {localeEN: "Grevenmacher", localeRU: "Гревенмахер"},
	"kirchberg":         {localeEN: "Kirchberg", localeRU: "Кирхберг"},
	"larochette":        {localeEN: "Larochette", localeRU: "Ларошетт"},
	"luxembourg-city":   {localeEN: "Luxembourg City", localeRU: "Люксембург"},
	"mondorf-les-bains": {localeEN: "Mondorf-les-Bains", localeRU: "Мондорф-ле-Бен"},
	"mullerthal":        {localeEN: "Mullerthal", localeRU: "Мюллерталь"},
	"remich":            {localeEN: "Remich", localeRU: "Ремих"},
	"schengen":          {localeEN: "Schengen", localeRU: "Шенген"},
	"vianden":           {localeEN: "Vianden", localeRU: "Вианден"},
	"wiltz":             {localeEN: "Wiltz", localeRU: "Вильц"},
}

var germanyCityNames = map[string]map[string]string{
	"baden-baden":              {localeEN: "Baden-Baden", localeRU: "Баден-Баден"},
	"berchtesgaden":            {localeEN: "Berchtesgaden", localeRU: "Берхтесгаден"},
	"berlin":                   {localeEN: "Berlin", localeRU: "Берлин"},
	"bonn":                     {localeEN: "Bonn", localeRU: "Бонн"},
	"bremen":                   {localeEN: "Bremen", localeRU: "Бремен"},
	"cologne":                  {localeEN: "Cologne", localeRU: "Кёльн"},
	"dresden":                  {localeEN: "Dresden", localeRU: "Дрезден"},
	"dusseldorf":               {localeEN: "Dusseldorf", localeRU: "Дюссельдорф"},
	"erfurt":                   {localeEN: "Erfurt", localeRU: "Эрфурт"},
	"frankfurt":                {localeEN: "Frankfurt", localeRU: "Франкфурт"},
	"freiburg":                 {localeEN: "Freiburg", localeRU: "Фрайбург"},
	"fussen":                   {localeEN: "Fussen", localeRU: "Фюссен"},
	"garmisch-partenkirchen":   {localeEN: "Garmisch-Partenkirchen", localeRU: "Гармиш-Партенкирхен"},
	"goslar":                   {localeEN: "Goslar", localeRU: "Гослар"},
	"hamburg":                  {localeEN: "Hamburg", localeRU: "Гамбург"},
	"hannover":                 {localeEN: "Hannover", localeRU: "Ганновер"},
	"heidelberg":               {localeEN: "Heidelberg", localeRU: "Гейдельберг"},
	"koblenz":                  {localeEN: "Koblenz", localeRU: "Кобленц"},
	"leipzig":                  {localeEN: "Leipzig", localeRU: "Лейпциг"},
	"lubeck":                   {localeEN: "Lubeck", localeRU: "Любек"},
	"mainz":                    {localeEN: "Mainz", localeRU: "Майнц"},
	"munich":                   {localeEN: "Munich", localeRU: "Мюнхен"},
	"nuremberg":                {localeEN: "Nuremberg", localeRU: "Нюрнберг"},
	"oberhausen":               {localeEN: "Oberhausen", localeRU: "Оберхаузен"},
	"potsdam":                  {localeEN: "Potsdam", localeRU: "Потсдам"},
	"rothenburg-ob-der-tauber": {localeEN: "Rothenburg ob der Tauber", localeRU: "Ротенбург-об-дер-Таубер"},
	"rugen":                    {localeEN: "Rugen", localeRU: "Рюген"},
	"rust":                     {localeEN: "Rust", localeRU: "Руст"},
	"stuttgart":                {localeEN: "Stuttgart", localeRU: "Штутгарт"},
	"sylt":                     {localeEN: "Sylt", localeRU: "Зюльт"},
	"trier":                    {localeEN: "Trier", localeRU: "Трир"},
	"weimar":                   {localeEN: "Weimar", localeRU: "Веймар"},
	"wernigerode":              {localeEN: "Wernigerode", localeRU: "Вернигероде"},
	"wolfsburg":                {localeEN: "Wolfsburg", localeRU: "Вольфсбург"},
}

var austriaCityNames = map[string]map[string]string{
	"bad-ischl":           {localeEN: "Bad Ischl", localeRU: "Бад-Ишль"},
	"bregenz":             {localeEN: "Bregenz", localeRU: "Брегенц"},
	"duernstein":          {localeEN: "Duernstein", localeRU: "Дюрнштайн"},
	"eisenstadt":          {localeEN: "Eisenstadt", localeRU: "Айзенштадт"},
	"goettweig":           {localeEN: "Goettweig", localeRU: "Гёттвайг"},
	"graz":                {localeEN: "Graz", localeRU: "Грац"},
	"grossglockner":       {localeEN: "Grossglockner", localeRU: "Гросглоккнер"},
	"hallstatt":           {localeEN: "Hallstatt", localeRU: "Халльштат"},
	"hinterbruehl":        {localeEN: "Hinterbruehl", localeRU: "Хинтербрюль"},
	"innsbruck":           {localeEN: "Innsbruck", localeRU: "Инсбрук"},
	"kaprun":              {localeEN: "Kaprun", localeRU: "Капрун"},
	"kitzbuhel":           {localeEN: "Kitzbuhel", localeRU: "Кицбюэль"},
	"klagenfurt":          {localeEN: "Klagenfurt", localeRU: "Клагенфурт"},
	"klosterneuburg":      {localeEN: "Klosterneuburg", localeRU: "Клостернойбург"},
	"krems":               {localeEN: "Krems", localeRU: "Кремс"},
	"laxenburg":           {localeEN: "Laxenburg", localeRU: "Лаксенбург"},
	"linz":                {localeEN: "Linz", localeRU: "Линц"},
	"mayrhofen":           {localeEN: "Mayrhofen", localeRU: "Майрхофен"},
	"melk":                {localeEN: "Melk", localeRU: "Мельк"},
	"petronell-carnuntum": {localeEN: "Petronell-Carnuntum", localeRU: "Петронелль-Карнунтум"},
	"salzburg":            {localeEN: "Salzburg", localeRU: "Зальцбург"},
	"solden":              {localeEN: "Solden", localeRU: "Зёльден"},
	"st-polten":           {localeEN: "St. Polten", localeRU: "Санкт-Пёльтен"},
	"st-wolfgang":         {localeEN: "St. Wolfgang", localeRU: "Санкт-Вольфганг"},
	"vienna":              {localeEN: "Vienna", localeRU: "Вена"},
	"villach":             {localeEN: "Villach", localeRU: "Филлах"},
	"voesendorf":          {localeEN: "Voesendorf", localeRU: "Фёсендорф"},
	"wachau":              {localeEN: "Wachau", localeRU: "Вахау"},
	"wels":                {localeEN: "Wels", localeRU: "Вельс"},
	"zell-am-see":         {localeEN: "Zell am See", localeRU: "Целль-ам-Зе"},
}

var australiaCityNames = map[string]map[string]string{
	"adelaide":         {localeEN: "Adelaide", localeRU: "Аделаида"},
	"airlie-beach":     {localeEN: "Airlie Beach", localeRU: "Эрли-Бич"},
	"alice-springs":    {localeEN: "Alice Springs", localeRU: "Алис-Спрингс"},
	"barossa-valley":   {localeEN: "Barossa Valley", localeRU: "Долина Баросса"},
	"blue-mountains":   {localeEN: "Blue Mountains", localeRU: "Голубые горы"},
	"brisbane":         {localeEN: "Brisbane", localeRU: "Брисбен"},
	"broome":           {localeEN: "Broome", localeRU: "Брум"},
	"byron-bay":        {localeEN: "Byron Bay", localeRU: "Байрон-Бей"},
	"cairns":           {localeEN: "Cairns", localeRU: "Кэрнс"},
	"canberra":         {localeEN: "Canberra", localeRU: "Канберра"},
	"darwin":           {localeEN: "Darwin", localeRU: "Дарвин"},
	"fremantle":        {localeEN: "Fremantle", localeRU: "Фримантл"},
	"gold-coast":       {localeEN: "Gold Coast", localeRU: "Голд-Кост"},
	"great-ocean-road": {localeEN: "Great Ocean Road", localeRU: "Великая океанская дорога"},
	"hobart":           {localeEN: "Hobart", localeRU: "Хобарт"},
	"kakadu":           {localeEN: "Kakadu", localeRU: "Какаду"},
	"kangaroo-island":  {localeEN: "Kangaroo Island", localeRU: "Остров Кенгуру"},
	"kuranda":          {localeEN: "Kuranda", localeRU: "Куранда"},
	"launceston":       {localeEN: "Launceston", localeRU: "Лонсестон"},
	"margaret-river":   {localeEN: "Margaret River", localeRU: "Маргарет-Ривер"},
	"melbourne":        {localeEN: "Melbourne", localeRU: "Мельбурн"},
	"noosa":            {localeEN: "Noosa", localeRU: "Нуса"},
	"perth":            {localeEN: "Perth", localeRU: "Перт"},
	"phillip-island":   {localeEN: "Phillip Island", localeRU: "Остров Филлип"},
	"port-douglas":     {localeEN: "Port Douglas", localeRU: "Порт-Дуглас"},
	"rottnest-island":  {localeEN: "Rottnest Island", localeRU: "Остров Роттнест"},
	"sunshine-coast":   {localeEN: "Sunshine Coast", localeRU: "Саншайн-Кост"},
	"sydney":           {localeEN: "Sydney", localeRU: "Сидней"},
	"uluru":            {localeEN: "Uluru", localeRU: "Улуру"},
	"whitsundays":      {localeEN: "Whitsundays", localeRU: "Уитсанди"},
}

var tanzaniaCityNames = map[string]map[string]string{
	"arusha":         {localeEN: "Arusha", localeRU: "Аруша"},
	"bagamoyo":       {localeEN: "Bagamoyo", localeRU: "Багамойо"},
	"dar-es-salaam":  {localeEN: "Dar es Salaam", localeRU: "Дар-эс-Салам"},
	"dodoma":         {localeEN: "Dodoma", localeRU: "Додома"},
	"gombe":          {localeEN: "Gombe", localeRU: "Гомбе"},
	"iringa":         {localeEN: "Iringa", localeRU: "Иринга"},
	"jambiani":       {localeEN: "Jambiani", localeRU: "Джамбиани"},
	"jozani":         {localeEN: "Jozani", localeRU: "Джозани"},
	"karatu":         {localeEN: "Karatu", localeRU: "Карату"},
	"kendwa":         {localeEN: "Kendwa", localeRU: "Кендва"},
	"kigoma":         {localeEN: "Kigoma", localeRU: "Кигома"},
	"kilimanjaro":    {localeEN: "Kilimanjaro", localeRU: "Килиманджаро"},
	"kitulo":         {localeEN: "Kitulo", localeRU: "Китуло"},
	"lake-manyara":   {localeEN: "Lake Manyara", localeRU: "Озеро Маньяра"},
	"mafia-island":   {localeEN: "Mafia Island", localeRU: "Остров Мафия"},
	"mahale":         {localeEN: "Mahale", localeRU: "Махале"},
	"mbeya":          {localeEN: "Mbeya", localeRU: "Мбея"},
	"mikumi":         {localeEN: "Mikumi", localeRU: "Микуми"},
	"mnemba":         {localeEN: "Mnemba", localeRU: "Мнемба"},
	"morogoro":       {localeEN: "Morogoro", localeRU: "Морогоро"},
	"moshi":          {localeEN: "Moshi", localeRU: "Моши"},
	"mount-meru":     {localeEN: "Mount Meru", localeRU: "Гора Меру"},
	"mwanza":         {localeEN: "Mwanza", localeRU: "Мванза"},
	"ngorongoro":     {localeEN: "Ngorongoro", localeRU: "Нгоронгоро"},
	"nungwi":         {localeEN: "Nungwi", localeRU: "Нунгви"},
	"nyerere":        {localeEN: "Nyerere", localeRU: "Ньерере"},
	"paje":           {localeEN: "Paje", localeRU: "Паже"},
	"pangani":        {localeEN: "Pangani", localeRU: "Пангани"},
	"ruaha":          {localeEN: "Ruaha", localeRU: "Руаха"},
	"rubondo-island": {localeEN: "Rubondo Island", localeRU: "Остров Рубондо"},
	"saadani":        {localeEN: "Saadani", localeRU: "Саадани"},
	"serengeti":      {localeEN: "Serengeti", localeRU: "Серенгети"},
	"stone-town":     {localeEN: "Stone Town", localeRU: "Стоун-Таун"},
	"tabora":         {localeEN: "Tabora", localeRU: "Табора"},
	"tanga":          {localeEN: "Tanga", localeRU: "Танга"},
	"tarangire":      {localeEN: "Tarangire", localeRU: "Тарангире"},
	"udzungwa":       {localeEN: "Udzungwa", localeRU: "Удзунгва"},
	"zanzibar-city":  {localeEN: "Zanzibar City", localeRU: "Занзибар"},
}

var kenyaCityNames = map[string]map[string]string{
	"aberdares":        {localeEN: "Aberdares", localeRU: "Абердэр"},
	"amboseli":         {localeEN: "Amboseli", localeRU: "Амбосели"},
	"diani":            {localeEN: "Diani", localeRU: "Диани"},
	"eldoret":          {localeEN: "Eldoret", localeRU: "Элдорет"},
	"hells-gate":       {localeEN: "Hell's Gate", localeRU: "Хеллс-Гейт"},
	"kakamega":         {localeEN: "Kakamega", localeRU: "Какамега"},
	"karen":            {localeEN: "Karen", localeRU: "Карен"},
	"kericho":          {localeEN: "Kericho", localeRU: "Керичо"},
	"kiambu":           {localeEN: "Kiambu", localeRU: "Киамбу"},
	"kilifi":           {localeEN: "Kilifi", localeRU: "Килифи"},
	"kisite-mpunguti":  {localeEN: "Kisite-Mpunguti", localeRU: "Кисите-Мпунгути"},
	"kisumu":           {localeEN: "Kisumu", localeRU: "Кисуму"},
	"kitale":           {localeEN: "Kitale", localeRU: "Китале"},
	"lake-baringo":     {localeEN: "Lake Baringo", localeRU: "Озеро Баринго"},
	"lake-bogoria":     {localeEN: "Lake Bogoria", localeRU: "Озеро Богория"},
	"lake-elementaita": {localeEN: "Lake Elementaita", localeRU: "Озеро Элементайта"},
	"lake-naivasha":    {localeEN: "Lake Naivasha", localeRU: "Озеро Найваша"},
	"lake-nakuru":      {localeEN: "Lake Nakuru", localeRU: "Озеро Накуру"},
	"lake-turkana":     {localeEN: "Lake Turkana", localeRU: "Озеро Туркана"},
	"lake-victoria":    {localeEN: "Lake Victoria", localeRU: "Озеро Виктория"},
	"laikipia":         {localeEN: "Laikipia", localeRU: "Лайкипия"},
	"lamu":             {localeEN: "Lamu", localeRU: "Ламу"},
	"langata":          {localeEN: "Langata", localeRU: "Лангата"},
	"malindi":          {localeEN: "Malindi", localeRU: "Малинди"},
	"marsabit":         {localeEN: "Marsabit", localeRU: "Марсабит"},
	"masai-mara":       {localeEN: "Masai Mara", localeRU: "Масаи-Мара"},
	"meru":             {localeEN: "Meru", localeRU: "Меру"},
	"mombasa":          {localeEN: "Mombasa", localeRU: "Момбаса"},
	"mount-kenya":      {localeEN: "Mount Kenya", localeRU: "Гора Кения"},
	"nairobi":          {localeEN: "Nairobi", localeRU: "Найроби"},
	"naivasha":         {localeEN: "Naivasha", localeRU: "Найваша"},
	"nakuru":           {localeEN: "Nakuru", localeRU: "Накуру"},
	"nanyuki":          {localeEN: "Nanyuki", localeRU: "Наньюки"},
	"narok":            {localeEN: "Narok", localeRU: "Нарок"},
	"ndere-island":     {localeEN: "Ndere Island", localeRU: "Остров Ндере"},
	"nyeri":            {localeEN: "Nyeri", localeRU: "Ньери"},
	"ol-pejeta":        {localeEN: "Ol Pejeta", localeRU: "Ол-Педжета"},
	"rusinga-island":   {localeEN: "Rusinga Island", localeRU: "Остров Русинга"},
	"samburu":          {localeEN: "Samburu", localeRU: "Самбуру"},
	"shimoni":          {localeEN: "Shimoni", localeRU: "Шимони"},
	"tsavo-east":       {localeEN: "Tsavo East", localeRU: "Восточный Цаво"},
	"tsavo-west":       {localeEN: "Tsavo West", localeRU: "Западный Цаво"},
	"watamu":           {localeEN: "Watamu", localeRU: "Ватаму"},
}

func init() {
	for cityID, names := range malaysiaCityNames {
		cityNames[cityID] = names
	}
	for cityID, names := range sriLankaCityNames {
		cityNames[cityID] = names
	}
	for cityID, names := range montenegroCityNames {
		cityNames[cityID] = names
	}
	for cityID, names := range indiaCityNames {
		cityNames[cityID] = names
	}
	for cityID, names := range maltaCityNames {
		cityNames[cityID] = names
	}
	for cityID, names := range cyprusCityNames {
		cityNames[cityID] = names
	}
	for cityID, names := range seychellesCityNames {
		cityNames[cityID] = names
	}
	for cityID, names := range polandCityNames {
		cityNames[cityID] = names
	}
	for cityID, names := range mexicoCityNames {
		cityNames[cityID] = names
	}
	for cityID, names := range brazilCityNames {
		cityNames[cityID] = names
	}
	for cityID, names := range abkhaziaCityNames {
		cityNames[cityID] = names
	}
	for cityID, names := range cubaCityNames {
		cityNames[cityID] = names
	}
	for cityID, names := range moroccoCityNames {
		cityNames[cityID] = names
	}
	for cityID, names := range portugalCityNames {
		cityNames[cityID] = names
	}
	for cityID, names := range italyCityNames {
		cityNames[cityID] = names
	}
	for cityID, names := range spainCityNames {
		cityNames[cityID] = names
	}
	for cityID, names := range luxembourgCityNames {
		cityNames[cityID] = names
	}
	for cityID, names := range germanyCityNames {
		cityNames[cityID] = names
	}
	for cityID, names := range austriaCityNames {
		cityNames[cityID] = names
	}
	for cityID, names := range australiaCityNames {
		cityNames[cityID] = names
	}
	for cityID, names := range tanzaniaCityNames {
		cityNames[cityID] = names
	}
	for cityID, names := range kenyaCityNames {
		cityNames[cityID] = names
	}
}

var languageNames = map[string]map[string]string{
	"en": {localeEN: "English", localeRU: "Английский"},
	"kk": {localeEN: "Kazakh", localeRU: "Казахский"},
	"ru": {localeEN: "Russian", localeRU: "Русский"},
}

var includedItemNames = map[string]map[string]string{
	"equipment": {localeEN: "Equipment", localeRU: "Снаряжение"},
	"food":      {localeEN: "Food", localeRU: "Питание"},
	"guide":     {localeEN: "Guide service", localeRU: "Услуги гида"},
	"photo":     {localeEN: "Photo support", localeRU: "Фотосопровождение"},
	"tickets":   {localeEN: "Tickets", localeRU: "Входные билеты"},
	"transport": {localeEN: "Transport", localeRU: "Транспорт"},
}

var meetingPointNames = map[string]map[string]string{
	"hotel pickup":        {localeEN: "Hotel pickup", localeRU: "Трансфер от отеля"},
	"main entrance":       {localeEN: "Main entrance", localeRU: "Главный вход"},
	"medeu entrance":      {localeEN: "Medeu entrance", localeRU: "Вход Медеу"},
	"medeu main entrance": {localeEN: "Medeu main entrance", localeRU: "Главный вход Медеу"},
	"visitor center":      {localeEN: "Visitor center", localeRU: "Визит-центр"},
}

func excursionTitleText(locale string, item *model.ExcursionModerationItem, fallback string) string {
	if item == nil {
		return strings.TrimSpace(fallback)
	}
	if title := localizedCopyTitle(locale, item.Translations); title != "" {
		return title
	}
	title := strings.TrimSpace(item.Title)
	productTitle := localizedCopyTitle(locale, item.ProductTranslations)
	if productTitle != "" && (title == "" || sameText(title, item.LandmarkName) || sameText(title, localizedCopyTitle(localeEN, item.ProductTranslations))) {
		return productTitle
	}
	if title != "" {
		return title
	}
	return strings.TrimSpace(fallback)
}

func excursionAttractionsText(locale string, item *model.ExcursionModerationItem) string {
	if item == nil {
		return ""
	}
	if landmark := localizedLandmarkName(locale, item); landmark != "" {
		return landmark
	}
	names := localizedAttractionNames(locale, item)
	return strings.Join(names, ", ")
}

func excursionGuidePrimaryText(item *model.ExcursionModerationItem) string {
	if item == nil {
		return "-"
	}
	if nickname := strings.TrimSpace(item.GuideNickname); nickname != "" {
		return nickname
	}
	if displayName := strings.TrimSpace(item.GuideDisplayName); displayName != "" {
		return displayName
	}
	if item.GuideUserID.String() != "00000000-0000-0000-0000-000000000000" {
		return "Guide " + shortString(item.GuideUserID.String())
	}
	return "-"
}

func excursionGuideFullNameText(item *model.ExcursionModerationItem) string {
	if item == nil {
		return ""
	}
	parts := make([]string, 0, 2)
	if lastName := strings.TrimSpace(item.GuideLastName); lastName != "" {
		parts = append(parts, lastName)
	}
	if firstName := strings.TrimSpace(item.GuideFirstName); firstName != "" {
		parts = append(parts, firstName)
	}
	fullName := strings.Join(parts, " ")
	if fullName != "" {
		return fullName
	}
	displayName := strings.TrimSpace(item.GuideDisplayName)
	nickname := strings.TrimSpace(item.GuideNickname)
	if displayName != "" && displayName != nickname {
		return displayName
	}
	return ""
}

func excursionLocationText(locale string, item *model.ExcursionModerationItem) string {
	if item == nil {
		return "-"
	}
	parts := make([]string, 0, 2)
	if city := displayCityName(locale, item.CityName); city != "" {
		parts = append(parts, city)
	} else if city := displayReferenceCityName(locale, item.DepartureCityID); city != "" {
		parts = append(parts, city)
	}
	if country := displayCountryName(locale, item.CountryCode); country != "" {
		parts = append(parts, country)
	}
	if len(parts) == 0 {
		return "-"
	}
	return strings.Join(parts, ", ")
}

func excursionSummaryText(locale string, item *model.ExcursionModerationItem) string {
	if item == nil {
		return "-"
	}
	if summary := localizedCopySummary(locale, item.Translations); summary != "" {
		return summary
	}
	summary := strings.TrimSpace(item.Summary)
	route := routeNameForCopy(locale, item)
	if isGeneratedSummary(summary) && route != "" {
		if productSummary := localizedCopySummary(locale, item.ProductTranslations); productSummary != "" {
			return productSummary
		}
		return moderationSummaryText(locale, route)
	}
	if summary != "" {
		return summary
	}
	if productSummary := localizedCopySummary(locale, item.ProductTranslations); productSummary != "" {
		return productSummary
	}
	if route != "" {
		return moderationSummaryText(locale, route)
	}
	return "-"
}

func excursionDescriptionText(locale string, item *model.ExcursionModerationItem) string {
	if item == nil {
		return "-"
	}
	if description := localizedCopyDescription(locale, item.Translations); description != "" {
		return description
	}
	description := strings.TrimSpace(item.Description)
	route := routeNameForCopy(locale, item)
	routeStops := routeStopsForCopy(locale, item)
	if isGeneratedDescription(description) && route != "" {
		if productDescription := localizedCopyDescription(locale, item.ProductTranslations); productDescription != "" {
			return productDescription
		}
		return moderationDescriptionText(locale, routeStops)
	}
	if description != "" {
		return description
	}
	if productDescription := localizedCopyDescription(locale, item.ProductTranslations); productDescription != "" {
		return productDescription
	}
	if route != "" {
		return moderationDescriptionText(locale, routeStops)
	}
	return "-"
}

func excursionDurationText(locale string, item *model.ExcursionModerationItem) string {
	if item == nil {
		return "-"
	}
	return durationMinutesText(locale, item.DurationMinutes)
}

func excursionMaxGroupText(locale string, item *model.ExcursionModerationItem) string {
	if item == nil || item.MaxGroupSize <= 0 {
		return "-"
	}
	if normalizeLocaleOrDefault(locale) == localeRU {
		return fmt.Sprintf("До %d гостей", item.MaxGroupSize)
	}
	if item.MaxGroupSize == 1 {
		return "Up to 1 guest"
	}
	return fmt.Sprintf("Up to %d guests", item.MaxGroupSize)
}

func excursionLanguagesText(locale string, item *model.ExcursionModerationItem) string {
	if item == nil || len(item.LanguageCodes) == 0 {
		return "-"
	}
	values := make([]string, 0, len(item.LanguageCodes))
	seen := make(map[string]struct{}, len(item.LanguageCodes))
	for _, code := range item.LanguageCodes {
		code = strings.ToLower(strings.TrimSpace(code))
		if code == "" {
			continue
		}
		if _, ok := seen[code]; ok {
			continue
		}
		seen[code] = struct{}{}
		if names, ok := languageNames[code]; ok {
			values = append(values, localizedValue(locale, names))
			continue
		}
		values = append(values, strings.ToUpper(code))
	}
	if len(values) == 0 {
		return "-"
	}
	return strings.Join(values, ", ")
}

func excursionMeetingPointText(locale string, item *model.ExcursionModerationItem) string {
	if item == nil {
		return "-"
	}
	locale = normalizeLocaleOrDefault(locale)
	if value := strings.TrimSpace(item.MeetingPointByLocale[locale]); value != "" {
		return value
	}
	if locale != defaultLocale {
		if value := strings.TrimSpace(item.MeetingPointByLocale[defaultLocale]); value != "" {
			return value
		}
	}
	if value := strings.TrimSpace(item.MeetingPoint); value != "" {
		if names, ok := meetingPointNames[strings.ToLower(value)]; ok {
			return localizedValue(locale, names)
		}
		return value
	}
	return "-"
}

func excursionIncludedItems(locale string, item *model.ExcursionModerationItem) []string {
	if item == nil {
		return nil
	}
	locale = normalizeLocaleOrDefault(locale)
	if values := normalizedNameList(item.IncludedItemsByLocale[locale]); len(values) > 0 {
		return values
	}
	if locale != defaultLocale {
		if values := normalizedNameList(item.IncludedItemsByLocale[defaultLocale]); len(values) > 0 {
			return values
		}
	}
	result := make([]string, 0, len(item.IncludedItems))
	seen := make(map[string]struct{}, len(item.IncludedItems))
	for _, value := range item.IncludedItems {
		key := strings.ToLower(strings.TrimSpace(value))
		if key == "" {
			continue
		}
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		if names, ok := includedItemNames[key]; ok {
			result = append(result, localizedValue(locale, names))
			continue
		}
		result = append(result, humanizeCityID(key))
	}
	return result
}

func itineraryTitleText(locale string, item model.ExcursionItineraryItem) string {
	if title := localizedItineraryTitle(locale, item.Translations); title != "" {
		return title
	}
	if title := strings.TrimSpace(item.Title); title != "" {
		return title
	}
	if name := strings.TrimSpace(item.AttractionName); name != "" {
		return name
	}
	return "-"
}

func itineraryDescriptionText(locale string, item model.ExcursionItineraryItem) string {
	if description := localizedItineraryDescription(locale, item.Translations); description != "" {
		return description
	}
	if description := strings.TrimSpace(item.Description); description != "" {
		return description
	}
	return ""
}

func itineraryAttractionText(item model.ExcursionItineraryItem) string {
	return strings.TrimSpace(item.AttractionName)
}

func itineraryStartText(offsetMinutes int) string {
	if offsetMinutes < 0 {
		offsetMinutes = 0
	}
	return fmt.Sprintf("%02d:%02d", offsetMinutes/60, offsetMinutes%60)
}

func itineraryDurationText(locale string, value *int) string {
	if value == nil {
		return ""
	}
	return durationMinutesText(locale, *value)
}

func itineraryTravelText(locale string, value *int) string {
	if value == nil || *value <= 0 {
		return ""
	}
	if normalizeLocaleOrDefault(locale) == localeRU {
		return "Переезд " + durationMinutesText(locale, *value)
	}
	return "Travel " + durationMinutesText(locale, *value)
}

func durationMinutesText(locale string, totalMinutes int) string {
	if totalMinutes <= 0 {
		return "-"
	}
	hours := totalMinutes / 60
	minutes := totalMinutes % 60
	if normalizeLocaleOrDefault(locale) == localeRU {
		switch {
		case hours > 0 && minutes > 0:
			return fmt.Sprintf("%d ч %d мин", hours, minutes)
		case hours > 0:
			return fmt.Sprintf("%d ч", hours)
		default:
			return fmt.Sprintf("%d мин", minutes)
		}
	}
	switch {
	case hours > 0 && minutes > 0:
		return fmt.Sprintf("%d h %d min", hours, minutes)
	case hours > 0:
		return fmt.Sprintf("%d h", hours)
	default:
		return fmt.Sprintf("%d min", minutes)
	}
}

func localizedItineraryTitle(locale string, items map[string]model.ExcursionItineraryLocalizedCopy) string {
	return localizedItineraryField(locale, items, func(item model.ExcursionItineraryLocalizedCopy) string {
		return item.Title
	})
}

func localizedItineraryDescription(locale string, items map[string]model.ExcursionItineraryLocalizedCopy) string {
	return localizedItineraryField(locale, items, func(item model.ExcursionItineraryLocalizedCopy) string {
		return item.Description
	})
}

func localizedItineraryField(locale string, items map[string]model.ExcursionItineraryLocalizedCopy, pick func(model.ExcursionItineraryLocalizedCopy) string) string {
	if len(items) == 0 {
		return ""
	}
	locale = normalizeLocaleOrDefault(locale)
	if value := strings.TrimSpace(pick(items[locale])); value != "" {
		return value
	}
	if locale != defaultLocale {
		if value := strings.TrimSpace(pick(items[defaultLocale])); value != "" {
			return value
		}
	}
	for _, item := range items {
		if value := strings.TrimSpace(pick(item)); value != "" {
			return value
		}
	}
	return ""
}

func moderationSummaryText(locale string, route string) string {
	if normalizeLocaleOrDefault(locale) == localeRU {
		return "Заявка гида на публикацию экскурсии: " + route + "."
	}
	return "Guide submission for publishing an excursion: " + route + "."
}

func moderationDescriptionText(locale string, route string) string {
	if normalizeLocaleOrDefault(locale) == localeRU {
		return "Экскурсия по направлению " + route + ". Проверьте программу, цену, место встречи и включенные услуги перед публикацией."
	}
	return "Excursion for " + route + ". Review the program, price, meeting point, and included items before publishing."
}

func routeNameForCopy(locale string, item *model.ExcursionModerationItem) string {
	if item == nil {
		return ""
	}
	if landmark := localizedLandmarkName(locale, item); landmark != "" {
		return landmark
	}
	names := localizedAttractionNames(locale, item)
	if len(names) > 0 {
		return strings.Join(names, " + ")
	}
	return ""
}

func routeStopsForCopy(locale string, item *model.ExcursionModerationItem) string {
	if item == nil {
		return ""
	}
	if landmark := localizedLandmarkName(locale, item); landmark != "" {
		return landmark
	}
	names := localizedAttractionNames(locale, item)
	if len(names) > 0 {
		return strings.Join(names, ", ")
	}
	return ""
}

func localizedLandmarkName(locale string, item *model.ExcursionModerationItem) string {
	if item == nil {
		return ""
	}
	if len(normalizedNameList(item.AttractionNames)) > 0 {
		return ""
	}
	if title := localizedCopyTitle(locale, item.ProductTranslations); title != "" {
		return title
	}
	return strings.TrimSpace(item.LandmarkName)
}

func localizedAttractionNames(locale string, item *model.ExcursionModerationItem) []string {
	if item == nil {
		return nil
	}
	locale = normalizeLocaleOrDefault(locale)
	if names := normalizedNameList(item.AttractionNamesByLocale[locale]); len(names) > 0 {
		return names
	}
	if locale != defaultLocale {
		if names := normalizedNameList(item.AttractionNamesByLocale[defaultLocale]); len(names) > 0 {
			return names
		}
	}
	for _, namesByLocale := range item.AttractionNamesByLocale {
		if names := normalizedNameList(namesByLocale); len(names) > 0 {
			return names
		}
	}
	return normalizedNameList(item.AttractionNames)
}

func localizedCopyTitle(locale string, items map[string]model.ExcursionLocalizedCopy) string {
	return localizedCopyField(locale, items, func(item model.ExcursionLocalizedCopy) string {
		return item.Title
	})
}

func localizedCopySummary(locale string, items map[string]model.ExcursionLocalizedCopy) string {
	return localizedCopyField(locale, items, func(item model.ExcursionLocalizedCopy) string {
		return item.Summary
	})
}

func localizedCopyDescription(locale string, items map[string]model.ExcursionLocalizedCopy) string {
	return localizedCopyField(locale, items, func(item model.ExcursionLocalizedCopy) string {
		return item.Description
	})
}

func localizedCopyField(locale string, items map[string]model.ExcursionLocalizedCopy, pick func(model.ExcursionLocalizedCopy) string) string {
	if len(items) == 0 {
		return ""
	}
	locale = normalizeLocaleOrDefault(locale)
	if value := strings.TrimSpace(pick(items[locale])); value != "" {
		return value
	}
	if locale != defaultLocale {
		if value := strings.TrimSpace(pick(items[defaultLocale])); value != "" {
			return value
		}
	}
	for _, item := range items {
		if value := strings.TrimSpace(pick(item)); value != "" {
			return value
		}
	}
	return ""
}

func isGeneratedSummary(value string) bool {
	value = strings.TrimSpace(value)
	return value == genericRouteSummary ||
		(strings.HasPrefix(value, "Compare guide offers for ") && strings.HasSuffix(value, "."))
}

func isGeneratedDescription(value string) bool {
	value = strings.TrimSpace(value)
	return value == genericRouteDescription ||
		strings.HasPrefix(value, "Choose a guide, language, price, meeting point")
}

func sameText(left string, right string) bool {
	return strings.EqualFold(strings.TrimSpace(left), strings.TrimSpace(right))
}

func normalizedNameList(values []string) []string {
	result := make([]string, 0, len(values))
	seen := make(map[string]struct{}, len(values))
	for _, value := range values {
		name := strings.TrimSpace(value)
		key := strings.ToLower(name)
		if key == "" {
			continue
		}
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		result = append(result, name)
	}
	return result
}

func displayCountryName(locale string, countryCode string) string {
	code := strings.ToUpper(strings.TrimSpace(countryCode))
	if code == "" {
		return ""
	}
	names, ok := countryNames[code]
	if !ok {
		return code
	}
	return localizedValue(locale, names)
}

func displayReferenceCityName(locale string, cityID string) string {
	id := strings.ToLower(strings.TrimSpace(cityID))
	if id == "" {
		return ""
	}
	if names, ok := cityNames[id]; ok {
		return localizedValue(locale, names)
	}
	return humanizeCityID(id)
}

func displayCityName(locale string, city string) string {
	name := strings.TrimSpace(city)
	if name == "" {
		return ""
	}
	if names, ok := localizedCityNamesForValue(name); ok {
		return localizedValue(locale, names)
	}
	return name
}

func localizedCityNamesForValue(value string) (map[string]string, bool) {
	key := strings.ToLower(strings.TrimSpace(value))
	if key == "" {
		return nil, false
	}
	if beforeComma, _, ok := strings.Cut(key, ","); ok {
		key = strings.TrimSpace(beforeComma)
	}
	if names, ok := cityNames[key]; ok {
		return names, true
	}
	for _, names := range cityNames {
		for _, name := range names {
			if strings.ToLower(strings.TrimSpace(name)) == key {
				return names, true
			}
		}
	}
	return nil, false
}

func humanizeCityID(value string) string {
	parts := strings.FieldsFunc(value, func(r rune) bool {
		return r == '-' || r == '_'
	})
	words := make([]string, 0, len(parts))
	for _, part := range parts {
		runes := []rune(part)
		if len(runes) == 0 {
			continue
		}
		runes[0] = unicode.ToUpper(runes[0])
		words = append(words, string(runes))
	}
	return strings.Join(words, " ")
}

func localizedValue(locale string, values map[string]string) string {
	locale = normalizeLocaleOrDefault(locale)
	if value := strings.TrimSpace(values[locale]); value != "" {
		return value
	}
	if value := strings.TrimSpace(values[defaultLocale]); value != "" {
		return value
	}
	for _, value := range values {
		if trimmed := strings.TrimSpace(value); trimmed != "" {
			return trimmed
		}
	}
	return ""
}

func normalizeLocaleOrDefault(locale string) string {
	if normalized, ok := normalizeLocale(locale); ok {
		return normalized
	}
	return defaultLocale
}
