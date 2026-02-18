local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Icons = {
    ["aperture"] = "rbxassetid://7733666258",
    ["bug"] = "rbxassetid://7733701545",
    ["chevrons-down-up"] = "rbxassetid://7733720483",
    ["clock-6"] = "rbxassetid://8997384977",
    ["egg"] = "rbxassetid://8997385940",
    ["external-link"] = "rbxassetid://7743866903",
    ["lightbulb-off"] = "rbxassetid://7733975123",
    ["file-check-2"] = "rbxassetid://7733779610",
    ["settings"] = "rbxassetid://7734053495",
    ["crown"] = "rbxassetid://7733765398",
    ["coins"] = "rbxassetid://7743866529",
    ["battery"] = "rbxassetid://7733674820",
    ["flashlight-off"] = "rbxassetid://7733798799",
    ["camera-off"] = "rbxassetid://7733919260",
    ["function-square"] = "rbxassetid://7733799682",
    ["mountain-snow"] = "rbxassetid://7743870286",    ["gamepad"] = "rbxassetid://7733799901",
    ["gift"] = "rbxassetid://7733946818",
    ["globe"] = "rbxassetid://7733954760",
    ["option"] = "rbxassetid://7734021300",
    ["hand"] = "rbxassetid://7733955740",
    ["hard-hat"] = "rbxassetid://7733955850",
    ["hash"] = "rbxassetid://7733955906",
    ["server"] = "rbxassetid://7734053426",
    ["align-horizontal-space-around"] = "rbxassetid://8997381738",
    ["highlighter"] = "rbxassetid://7743868648",
    ["bike"] = "rbxassetid://7733678330",
    ["home"] = "rbxassetid://7733960981",
    ["image"] = "rbxassetid://7733964126",
    ["indent"] = "rbxassetid://7733964452",
    ["infinity"] = "rbxassetid://7733964640",
    ["inspect"] = "rbxassetid://7733964808",
    ["alert-triangle"] = "rbxassetid://7733658504",
    ["align-start-horizontal"] = "rbxassetid://8997381965",
    ["figma"] = "rbxassetid://7743867310",
    ["pin"] = "rbxassetid://8997386648",
    ["corner-up-right"] = "rbxassetid://7733764915",
    ["list-x"] = "rbxassetid://7743869517",
    ["monitor-off"] = "rbxassetid://7734000184",
    ["chevron-first"] = "rbxassetid://8997383275",
    ["package-search"] = "rbxassetid://8997386448",
    ["pencil"] = "rbxassetid://7734022107",
    ["cloud-fog"] = "rbxassetid://7733920317",
    ["grip-horizontal"] = "rbxassetid://7733955302",
    ["align-center-vertical"] = "rbxassetid://8997380737",
    ["outdent"] = "rbxassetid://7734021384",
    ["more-vertical"] = "rbxassetid://7734006187",
    ["package-plus"] = "rbxassetid://8997386355",
    ["bluetooth"] = "rbxassetid://7733687147",
    ["pen-tool"] = "rbxassetid://7734022041",
    ["person-standing"] = "rbxassetid://7743871002",
    ["tornado"] = "rbxassetid://7743873633",
    ["phone-incoming"] = "rbxassetid://7743871120",
    ["phone-off"] = "rbxassetid://7734029534",
    ["dribbble"] = "rbxassetid://7733770843",
    ["at-sign"] = "rbxassetid://7733673907",
    ["edit-2"] = "rbxassetid://7733771217",
    ["sheet"] = "rbxassetid://7743871876",
    ["tv"] = "rbxassetid://7743874674",
    ["headphones"] = "rbxassetid://7733956063",
    ["qr-code"] = "rbxassetid://7743871575",
    ["reply"] = "rbxassetid://7734051594",
    ["rewind"] = "rbxassetid://7734051670",
    ["bell-off"] = "rbxassetid://7733675107",
    ["file-check"] = "rbxassetid://7733779668",
    ["quote"] = "rbxassetid://7734045100",    ["rotate-ccw"] = "rbxassetid://7734051861",
    ["library"] = "rbxassetid://7743869054",
    ["clock-1"] = "rbxassetid://8997383694",
    ["on-charge"] = "rbxassetid://7734021231",
    ["video-off"] = "rbxassetid://7743876466",
    ["save"] = "rbxassetid://7734052335",
    ["arrow-left-circle"] = "rbxassetid://7733673056",
    ["screen-share"] = "rbxassetid://7734052814",
    ["clock-3"] = "rbxassetid://8997384456",
    ["help-circle"] = "rbxassetid://7733956210",
    ["server-crash"] = "rbxassetid://7734053281",
    ["bluetooth-searching"] = "rbxassetid://7733914320",
    ["equal"] = "rbxassetid://7733771811",
    ["shield-close"] = "rbxassetid://7734056470",
    ["phone"] = "rbxassetid://7734032056",
    ["type"] = "rbxassetid://7743874740",
    ["file-x-2"] = "rbxassetid://7743867554",
    ["sidebar"] = "rbxassetid://7734058260",
    ["sigma"] = "rbxassetid://7734058345",
    ["smartphone-charging"] = "rbxassetid://7734058894",
    ["arrow-left"] = "rbxassetid://7733673136",
    ["framer"] = "rbxassetid://7733799486",
    ["currency"] = "rbxassetid://7733765592",
    ["star"] = "rbxassetid://7734068321",
    ["stretch-horizontal"] = "rbxassetid://8997387754",
    ["smile"] = "rbxassetid://7734059095",
    ["subscript"] = "rbxassetid://8997387937",
    ["sun"] = "rbxassetid://7734068495",
    ["switch-camera"] = "rbxassetid://7743872492",
    ["table"] = "rbxassetid://7734073253",
    ["tag"] = "rbxassetid://7734075797",
    ["cross"] = "rbxassetid://7733765224",
    ["gem"] = "rbxassetid://7733942651",
    ["link"] = "rbxassetid://7733978098",
    ["terminal"] = "rbxassetid://7743872929",
    ["thermometer-sun"] = "rbxassetid://7734084018",
    ["share-2"] = "rbxassetid://7734053595",
    ["timer-off"] = "rbxassetid://8997388325",
    ["megaphone"] = "rbxassetid://7733993049",
    ["timer-reset"] = "rbxassetid://7743873336",
    ["phone-forwarded"] = "rbxassetid://7734027345",
    ["unlock"] = "rbxassetid://7743875263",
    ["trello"] = "rbxassetid://7743873996",
    ["camera"] = "rbxassetid://7733708692",
    ["triangle"] = "rbxassetid://7743874367",
    ["truck"] = "rbxassetid://7743874482",
    ["file-output"] = "rbxassetid://7733788742",
    ["gamepad-2"] = "rbxassetid://7733799795",
    ["network"] = "rbxassetid://7734021047",
    ["users"] = "rbxassetid://7743876054",    ["electricity-off"] = "rbxassetid://7733771563",
    ["book"] = "rbxassetid://7733914390",
    ["clock-9"] = "rbxassetid://8997385485",
    ["corner-down-left"] = "rbxassetid://7733764327",
    ["locate-fixed"] = "rbxassetid://7733992424",
    ["bar-chart"] = "rbxassetid://7733674319",
    ["shield-check"] = "rbxassetid://7734056411",
    ["signal-low"] = "rbxassetid://8997387189",
    ["reply-all"] = "rbxassetid://7734051524",
    ["zoom-in"] = "rbxassetid://7743878977",
    ["grip-vertical"] = "rbxassetid://7733955410",
    ["ticket"] = "rbxassetid://7734086558",
    ["smartphone"] = "rbxassetid://7734058979",
    ["arrow-big-right"] = "rbxassetid://7733671493",
    ["tv-2"] = "rbxassetid://7743874599",
    ["flashlight"] = "rbxassetid://7733798851",
    ["database"] = "rbxassetid://7743866778",
    ["plus-square"] = "rbxassetid://7734040369",
    ["align-justify"] = "rbxassetid://7733661326",
    ["clipboard-list"] = "rbxassetid://7733920117",
    ["github"] = "rbxassetid://7733954058",
    ["columns"] = "rbxassetid://7733757178",
    ["arrow-big-down"] = "rbxassetid://7733668653",
    ["cloud-off"] = "rbxassetid://7733745572",
    ["target"] = "rbxassetid://7743872758",
    ["skip-back"] = "rbxassetid://7734058404",
    ["x-circle"] = "rbxassetid://7743878496",
    ["clock-10"] = "rbxassetid://8997383876",
    ["align-right"] = "rbxassetid://7733663582",
    ["clock-5"] = "rbxassetid://8997384798",
    ["bell-plus"] = "rbxassetid://7733675181",
    ["battery-medium"] = "rbxassetid://7733674731",
    ["arrow-down"] = "rbxassetid://7733672933",
    ["inbox"] = "rbxassetid://7733964370",
    ["cast"] = "rbxassetid://7733919326",
    ["gift-card"] = "rbxassetid://7733945018",
    ["webcam"] = "rbxassetid://7743877896",
    ["folder-minus"] = "rbxassetid://7733799022",
    ["scan-line"] = "rbxassetid://8997386772",
    ["shovel"] = "rbxassetid://7734056878",
    ["download-cloud"] = "rbxassetid://7733770689",
    ["list-checks"] = "rbxassetid://7743869317",
    ["file-text"] = "rbxassetid://7733789088",
    ["codesandbox"] = "rbxassetid://7733752575",
    ["laptop-2"] = "rbxassetid://7733965313",
    ["podcast"] = "rbxassetid://7734042234",
    ["log-out"] = "rbxassetid://7733992677",
    ["thumbs-up"] = "rbxassetid://7743873212",
    ["timer"] = "rbxassetid://7743873443",
    ["text-cursor"] = "rbxassetid://8997388195",    ["file-search"] = "rbxassetid://7733788966",
    ["thermometer"] = "rbxassetid://7734084149",
    ["bluetooth-off"] = "rbxassetid://7733914252",
    ["refresh-cw"] = "rbxassetid://7734051052",
    ["clipboard-check"] = "rbxassetid://7733919947",
    ["languages"] = "rbxassetid://7733965249",
    ["asterisk"] = "rbxassetid://7733673800",
    ["superscript"] = "rbxassetid://8997388036",
    ["user-check"] = "rbxassetid://7743875503",
    ["move-diagonal"] = "rbxassetid://7743870505",
    ["copy"] = "rbxassetid://7733764083",
    ["bot"] = "rbxassetid://7733916988",
    ["alarm-minus"] = "rbxassetid://7733656164",
    ["log-in"] = "rbxassetid://7733992604",
    ["maximize"] = "rbxassetid://7733992982",
    ["align-horizontal-space-between"] = "rbxassetid://8997381854",
    ["brush"] = "rbxassetid://7733701455",
    ["equal-not"] = "rbxassetid://7733771726",
    ["upload"] = "rbxassetid://7743875428",
    ["minus-circle"] = "rbxassetid://7733998053",
    ["graduation-cap"] = "rbxassetid://7733955058",
    ["edit-3"] = "rbxassetid://7733771361",
    ["check"] = "rbxassetid://7733715400",
    ["scissors"] = "rbxassetid://7734052570",
    ["info"] = "rbxassetid://7733964719",
    ["align-horizonal-distribute-start"] = "rbxassetid://8997381290",
    ["book-open"] = "rbxassetid://7733687281",
    ["divide-circle"] = "rbxassetid://7733769152",
    ["file"] = "rbxassetid://7733793319",
    ["clock-2"] = "rbxassetid://8997384295",
    ["corner-right-up"] = "rbxassetid://7733764680",
    ["clover"] = "rbxassetid://7733747233",
    ["expand"] = "rbxassetid://7733771982",
    ["gauge"] = "rbxassetid://7733799969",
    ["phone-outgoing"] = "rbxassetid://7743871253",
    ["shield-alert"] = "rbxassetid://7734056326",
    ["paperclip"] = "rbxassetid://7734021680",
    ["arrow-big-left"] = "rbxassetid://7733911731",
    ["album"] = "rbxassetid://7733658133",
    ["bookmark"] = "rbxassetid://7733692043",
    ["check-circle-2"] = "rbxassetid://7733710700",
    ["list-ordered"] = "rbxassetid://7743869411",
    ["delete"] = "rbxassetid://7733768142",
    ["axe"] = "rbxassetid://7733674079",
    ["radio"] = "rbxassetid://7743871662",
    ["octagon"] = "rbxassetid://7734021165",
    ["git-commit"] = "rbxassetid://7743868360",
    ["shirt"] = "rbxassetid://7734056672",
    ["corner-right-down"] = "rbxassetid://7733764605",
    ["trending-down"] = "rbxassetid://7743874143",    ["airplay"] = "rbxassetid://7733655834",
    ["repeat"] = "rbxassetid://7734051454",
    ["layers"] = "rbxassetid://7743868936",
    ["chevron-right"] = "rbxassetid://7733717755",
    ["chevrons-right"] = "rbxassetid://7733919682",
    ["folder-plus"] = "rbxassetid://7733799092",
    ["alarm-check"] = "rbxassetid://7733655912",
    ["arrow-up-right"] = "rbxassetid://7733673646",
    ["user-plus"] = "rbxassetid://7743875759",
    ["file-minus"] = "rbxassetid://7733936115",
    ["cloud-drizzle"] = "rbxassetid://7733920226",
    ["stretch-vertical"] = "rbxassetid://8997387862",
    ["align-vertical-distribute-start"] = "rbxassetid://8997382428",
    ["unlink"] = "rbxassetid://7743875149",
    ["wand"] = "rbxassetid://8997388430",
    ["regex"] = "rbxassetid://7734051188",
    ["command"] = "rbxassetid://7733924046",
    ["haze"] = "rbxassetid://7733955969",
    ["trash"] = "rbxassetid://7743873871",
    ["battery-full"] = "rbxassetid://7733674503",
    ["flag-triangle-left"] = "rbxassetid://7733798509",
    ["server-off"] = "rbxassetid://7734053361",
    ["loader-2"] = "rbxassetid://7733989869",
    ["monitor-speaker"] = "rbxassetid://7743869988",
    ["shuffle"] = "rbxassetid://7734057059",
    ["tablet"] = "rbxassetid://7743872620",
    ["cloud-moon"] = "rbxassetid://7733920519",
    ["clipboard-x"] = "rbxassetid://7733734668",
    ["pocket"] = "rbxassetid://7734042139",
    ["watch"] = "rbxassetid://7743877668",
    ["file-plus"] = "rbxassetid://7733788885",
    ["locate"] = "rbxassetid://7733992469",
    ["share"] = "rbxassetid://7734053697",
    ["thermometer-snowflake"] = "rbxassetid://7743873074",
    ["volume-1"] = "rbxassetid://7743877081",
    ["arrow-left-right"] = "rbxassetid://8997382869",
    ["coffee"] = "rbxassetid://7733752630",
    ["chevron-last"] = "rbxassetid://8997383390",
    ["cloud-hail"] = "rbxassetid://7733920444",
    ["alarm-clock-off"] = "rbxassetid://7733656003",
    ["pound-sterling"] = "rbxassetid://7734042354",
    ["tent"] = "rbxassetid://7734078943",
    ["toggle-left"] = "rbxassetid://7734091286",
    ["dollar-sign"] = "rbxassetid://7733770599",
    ["sunrise"] = "rbxassetid://7743872365",
    ["sunset"] = "rbxassetid://7734070982",
    ["code"] = "rbxassetid://7733749837",
    ["thumbs-down"] = "rbxassetid://7734084236",
    ["trending-up"] = "rbxassetid://7743874262",
    ["clock-12"] = "rbxassetid://8997384150",    ["rocking-chair"] = "rbxassetid://7734051769",
    ["check-square"] = "rbxassetid://7733919526",
    ["cpu"] = "rbxassetid://7733765045",
    ["palette"] = "rbxassetid://7734021595",
    ["minimize-2"] = "rbxassetid://7733997870",
    ["cloud-sun"] = "rbxassetid://7733746880",
    ["copyleft"] = "rbxassetid://7733764196",
    ["archive"] = "rbxassetid://7733911621",
    ["building"] = "rbxassetid://7733701625",
    ["image-minus"] = "rbxassetid://7733963797",
    ["italic"] = "rbxassetid://7733964917",
    ["link-2-off"] = "rbxassetid://7733975283",
    ["sort-asc"] = "rbxassetid://7734060715",
    ["underline"] = "rbxassetid://7743874904",
    ["gitlab"] = "rbxassetid://7733954246",
    ["file-minus-2"] = "rbxassetid://7733936010",
    ["play-circle"] = "rbxassetid://7734037784",
    ["clock-8"] = "rbxassetid://8997385352",
    ["file-input"] = "rbxassetid://7733935917",
    ["beaker"] = "rbxassetid://7733674922",
    ["shopping-bag"] = "rbxassetid://7734056747",
    ["navigation"] = "rbxassetid://7734020989",
    ["moon"] = "rbxassetid://7743870134",
    ["align-vertical-space-between"] = "rbxassetid://8997382793",
    ["glasses"] = "rbxassetid://7733954403",
    ["clipboard-copy"] = "rbxassetid://7733920037",
    ["feather"] = "rbxassetid://7733777166",
    ["skip-forward"] = "rbxassetid://7734058495",
    ["wind"] = "rbxassetid://7743878264",
    ["frown"] = "rbxassetid://7733799591",
    ["move-vertical"] = "rbxassetid://7743870608",
    ["umbrella"] = "rbxassetid://7743874820",
    ["package"] = "rbxassetid://7734021469",
    ["chevrons-up"] = "rbxassetid://7733723433",
    ["download"] = "rbxassetid://7733770755",
    ["eye"] = "rbxassetid://7733774602",
    ["files"] = "rbxassetid://7743867811",
    ["arrow-down-right"] = "rbxassetid://7733672831",
    ["code-2"] = "rbxassetid://7733920644",
    ["wrap-text"] = "rbxassetid://8997388548",
    ["file-digit"] = "rbxassetid://7733935829",
    ["x-square"] = "rbxassetid://7743878737",
    ["clipboard"] = "rbxassetid://7733734762",
    ["maximize-2"] = "rbxassetid://7733992901",
    ["send"] = "rbxassetid://7734053039",
    ["alarm-clock"] = "rbxassetid://7733656100",
    ["sliders"] = "rbxassetid://7734058803",
    ["refresh-ccw"] = "rbxassetid://7734050715",
    ["music"] = "rbxassetid://7734020554",
    ["banknote"] = "rbxassetid://7733674153",    ["hard-drive"] = "rbxassetid://7733955793",
    ["search"] = "rbxassetid://7734052925",
    ["layout-list"] = "rbxassetid://7733970442",
    ["edit"] = "rbxassetid://7733771472",
    ["contrast"] = "rbxassetid://7733764005",
    ["wifi"] = "rbxassetid://7743878148",
    ["swiss-franc"] = "rbxassetid://7734071038",
    ["ghost"] = "rbxassetid://7743868000",
    ["laptop"] = "rbxassetid://7733965386",
    ["clock-4"] = "rbxassetid://8997384603",
    ["layout-dashboard"] = "rbxassetid://7733970318",
    ["align-vertical-justify-end"] = "rbxassetid://8997382584",
    ["circle"] = "rbxassetid://7733919881",
    ["file-x"] = "rbxassetid://7733938136",
    ["award"] = "rbxassetid://7733673987",
    ["corner-left-down"] = "rbxassetid://7733764448",
    ["arrow-up-left"] = "rbxassetid://7733673539",
    ["carrot"] = "rbxassetid://8997382987",
    ["globe-2"] = "rbxassetid://7733954611",
    ["compass"] = "rbxassetid://7733924216",
    ["git-branch"] = "rbxassetid://7733949149",
    ["vibrate"] = "rbxassetid://7743876302",
    ["pause-circle"] = "rbxassetid://7734021767",
    ["minus-square"] = "rbxassetid://7743869899",
    ["mic-off"] = "rbxassetid://7743869714",
    ["arrow-down-circle"] = "rbxassetid://7733671763",
    ["move-horizontal"] = "rbxassetid://7734016210",
    ["chrome"] = "rbxassetid://7733919783",
    ["radio-receiver"] = "rbxassetid://7734045155",
    ["shield"] = "rbxassetid://7734056608",
    ["image-plus"] = "rbxassetid://7733964016",
    ["more-horizontal"] = "rbxassetid://7734006080",
    ["slash"] = "rbxassetid://8997387644",
    ["divide"] = "rbxassetid://7733769365",
    ["view"] = "rbxassetid://7743876754",
    ["list"] = "rbxassetid://7743869612",
    ["printer"] = "rbxassetid://7734042580",
    ["corner-left-up"] = "rbxassetid://7733764536",
    ["meh"] = "rbxassetid://7733993147",
    ["copyright"] = "rbxassetid://7733764275",
    ["align-end-vertical"] = "rbxassetid://8997380907",
    ["heart"] = "rbxassetid://7733956134",
    ["lock"] = "rbxassetid://7733992528",
    ["align-center"] = "rbxassetid://7733909776",
    ["signal-high"] = "rbxassetid://8997387110",
    ["upload-cloud"] = "rbxassetid://7743875358",
    ["arrow-up-circle"] = "rbxassetid://7733673466",
    ["git-branch-plus"] = "rbxassetid://7743868200",
    ["align-vertical-justify-center"] = "rbxassetid://8997382502",
    ["screen-share-off"] = "rbxassetid://7734052653",    ["git-pull-request"] = "rbxassetid://7733952287",
    ["flag"] = "rbxassetid://7733798691",
    ["star-half"] = "rbxassetid://7734068258",
    ["minus"] = "rbxassetid://7734000129",
    ["mountain"] = "rbxassetid://7734008868",
    ["volume"] = "rbxassetid://7743877487",
    ["mouse-pointer-2"] = "rbxassetid://7734010405",
    ["package-x"] = "rbxassetid://8997386545",
    ["indian-rupee"] = "rbxassetid://7733964536",
    ["speaker"] = "rbxassetid://7734063416",
    ["flame"] = "rbxassetid://7733798747",
    ["circle-slashed"] = "rbxassetid://8997383530",
    ["crop"] = "rbxassetid://7733765140",
    ["clock-11"] = "rbxassetid://8997384034",
    ["stop-circle"] = "rbxassetid://7734068379",
    ["align-horizontal-justify-end"] = "rbxassetid://8997381549",
    ["power-off"] = "rbxassetid://7734042423",
    ["bell-minus"] = "rbxassetid://7733675028",
    ["undo"] = "rbxassetid://7743874974",
    ["link-2"] = "rbxassetid://7743869163",
    ["lightbulb"] = "rbxassetid://7733975185",
    ["shrink"] = "rbxassetid://7734056971",
    ["mail"] = "rbxassetid://7733992732",
    ["pause"] = "rbxassetid://7734021897",
    ["bold"] = "rbxassetid://7733687211",
    ["calendar"] = "rbxassetid://7733919198",
    ["x-octagon"] = "rbxassetid://7743878618",
    ["russian-ruble"] = "rbxassetid://7734052248",
    ["file-code"] = "rbxassetid://7733779730",
    ["life-buoy"] = "rbxassetid://7733973479",
    ["import"] = "rbxassetid://7733964240",
    ["video"] = "rbxassetid://7743876610",
    ["clock-7"] = "rbxassetid://8997385147",
    ["align-center-horizontal"] = "rbxassetid://8997380477",
    ["bell"] = "rbxassetid://7733911828",
    ["move-diagonal-2"] = "rbxassetid://7734013178",
    ["message-circle"] = "rbxassetid://7733993311",
    ["skull"] = "rbxassetid://7734058599",
    ["battery-charging"] = "rbxassetid://7733674402",
    ["ruler"] = "rbxassetid://7734052157",
    ["binary"] = "rbxassetid://7733678388",
    ["cloud-rain-wind"] = "rbxassetid://7733746456",
    ["briefcase"] = "rbxassetid://7733919017",
    ["terminal-square"] = "rbxassetid://7734079055",
    ["scale"] = "rbxassetid://7734052454",
    ["lasso"] = "rbxassetid://7733967892",
    ["piggy-bank"] = "rbxassetid://7734034513",
    ["battery-low"] = "rbxassetid://7733674589",
    ["arrow-up"] = "rbxassetid://7733673717",
    ["list-plus"] = "rbxassetid://7733984995",    ["bookmark-plus"] = "rbxassetid://7734111084",
    ["box-select"] = "rbxassetid://7733696665",
    ["filter"] = "rbxassetid://7733798407",
    ["play"] = "rbxassetid://7743871480",
    ["align-vertical-space-around"] = "rbxassetid://8997382708",
    ["calculator"] = "rbxassetid://7733919105",
    ["bell-ring"] = "rbxassetid://7733675275",
    ["plane"] = "rbxassetid://7734037723",
    ["plus-circle"] = "rbxassetid://7734040271",
    ["power"] = "rbxassetid://7734042493",
    ["phone-missed"] = "rbxassetid://7734029465",
    ["percent"] = "rbxassetid://7743870852",
    ["jersey-pound"] = "rbxassetid://7733965029",
    ["mouse-pointer"] = "rbxassetid://7743870392",
    ["box"] = "rbxassetid://7733917120",
    ["separator-vertical"] = "rbxassetid://7734053213",
    ["snowflake"] = "rbxassetid://7734059180",
    ["sort-desc"] = "rbxassetid://7743871973",
    ["flag-triangle-right"] = "rbxassetid://7733798634",
    ["bar-chart-2"] = "rbxassetid://7733674239",
    ["hand-metal"] = "rbxassetid://7733955664",
    ["map"] = "rbxassetid://7733992829",
    ["eye-off"] = "rbxassetid://7733774495",
    ["align-end-horizontal"] = "rbxassetid://8997380820",
    ["cloud-rain"] = "rbxassetid://7733746651",
    ["contact"] = "rbxassetid://7743866666",
    ["signal"] = "rbxassetid://8997387546",
    ["mouse-pointer-click"] = "rbxassetid://7734010488",
    ["settings-2"] = "rbxassetid://8997386997",
    ["sidebar-open"] = "rbxassetid://7734058165",
    ["unlink-2"] = "rbxassetid://7743875069",
    ["pause-octagon"] = "rbxassetid://7734021827",
    ["user-minus"] = "rbxassetid://7743875629",
    ["cloud"] = "rbxassetid://7733746980",
    ["arrow-right-circle"] = "rbxassetid://7733673229",
    ["align-horizonal-distribute-center"] = "rbxassetid://8997381028",
    ["fast-forward"] = "rbxassetid://7743867090",
    ["volume-2"] = "rbxassetid://7743877250",
    ["grab"] = "rbxassetid://7733954884",
    ["arrow-right"] = "rbxassetid://7733673345",
    ["chevron-down"] = "rbxassetid://7733717447",
    ["volume-x"] = "rbxassetid://7743877381",
    ["cloud-snow"] = "rbxassetid://7733746798",
    ["car"] = "rbxassetid://7733708835",
    ["bluetooth-connected"] = "rbxassetid://7734110952",
    ["CD"] = "rbxassetid://7734110220",
    ["cookie"] = "rbxassetid://8997385628",
    ["message-square"] = "rbxassetid://7733993369",
    ["repeat-1"] = "rbxassetid://7734051342",
    ["codepen"] = "rbxassetid://7733920768",    ["voicemail"] = "rbxassetid://7743876916",
    ["text-cursor-input"] = "rbxassetid://8997388094",
    ["package-check"] = "rbxassetid://8997386143",
    ["shopping-cart"] = "rbxassetid://7734056813",
    ["corner-down-right"] = "rbxassetid://7733764385",
    ["folder-open"] = "rbxassetid://8997386062",
    ["charge"] = "rbxassetid://8997383136",
    ["layout-grid"] = "rbxassetid://7733970390",
    ["clock"] = "rbxassetid://7733734848",
    ["corner-up-left"] = "rbxassetid://7733764800",
    ["align-horizontal-justify-start"] = "rbxassetid://8997381652",
    ["git-merge"] = "rbxassetid://7733952195",
    ["verified"] = "rbxassetid://7743876142",
    ["redo"] = "rbxassetid://7743871739",
    ["hexagon"] = "rbxassetid://7743868527",
    ["square"] = "rbxassetid://7743872181",
    ["align-horizontal-justify-center"] = "rbxassetid://8997381461",
    ["chevrons-up-down"] = "rbxassetid://7733723321",
    ["bus"] = "rbxassetid://7733701715",
    ["file-plus-2"] = "rbxassetid://7733788816",
    ["alarm-plus"] = "rbxassetid://7733658066",
    ["divide-square"] = "rbxassetid://7733769261",
    ["pie-chart"] = "rbxassetid://7734034378",
    ["signal-zero"] = "rbxassetid://8997387434",
    ["hammer"] = "rbxassetid://7733955511",
    ["history"] = "rbxassetid://7733960880",
    ["align-vertical-justify-start"] = "rbxassetid://8997382639",
    ["flask-round"] = "rbxassetid://7733798957",
    ["wifi-off"] = "rbxassetid://7743878056",
    ["zoom-out"] = "rbxassetid://7743879082",
    ["toggle-right"] = "rbxassetid://7743873539",
    ["monitor"] = "rbxassetid://7734002839",
    ["x"] = "rbxassetid://7743878857",
    ["align-horizonal-distribute-end"] = "rbxassetid://8997381144",
    ["user"] = "rbxassetid://7743875962",
    ["sprout"] = "rbxassetid://7743872071",
    ["move"] = "rbxassetid://7743870731",
    ["gavel"] = "rbxassetid://7733800044",
    ["package-minus"] = "rbxassetid://8997386266",
    ["drumstick"] = "rbxassetid://8997385789",
    ["forward"] = "rbxassetid://7733799371",
    ["sidebar-close"] = "rbxassetid://7734058092",
    ["electricity"] = "rbxassetid://7733771628",
    ["plus"] = "rbxassetid://7734042071",
    ["pipette"] = "rbxassetid://7743871384",
    ["cloud-lightning"] = "rbxassetid://7733741741",
    ["lasso-select"] = "rbxassetid://7743868832",
    ["phone-call"] = "rbxassetid://7734027264",
    ["droplet"] = "rbxassetid://7733770982",
    ["key"] = "rbxassetid://7733965118",    ["map-pin"] = "rbxassetid://7733992789",
    ["navigation-2"] = "rbxassetid://7734020942",
    ["list-minus"] = "rbxassetid://7733980795",
    ["chevron-up"] = "rbxassetid://7733919605",
    ["layout-template"] = "rbxassetid://7733970494",
    ["no_entry"] = "rbxassetid://7734021118",
    ["scan"] = "rbxassetid://8997386861",
    ["arrow-big-up"] = "rbxassetid://7733671663",
    ["bookmark-minus"] = "rbxassetid://7733689754",
    ["activity"] = "rbxassetid://7733655755",
    ["grid"] = "rbxassetid://7733955179",
    ["user-x"] = "rbxassetid://7743875879",
    ["alert-circle"] = "rbxassetid://7733658271",
    ["menu"] = "rbxassetid://7733993211",
    ["form-input"] = "rbxassetid://7733799275",
    ["rss"] = "rbxassetid://7734052075",
    ["loader"] = "rbxassetid://7733992358",
    ["align-vertical-distribute-end"] = "rbxassetid://8997382326",
    ["strikethrough"] = "rbxassetid://7734068425",
    ["mic"] = "rbxassetid://7743869805",
    ["landmark"] = "rbxassetid://7733965184",
    ["crosshair"] = "rbxassetid://7733765307",
    ["alert-octagon"] = "rbxassetid://7733658335",
    ["anchor"] = "rbxassetid://7733911490",
    ["separator-horizontal"] = "rbxassetid://7734053146",
    ["chevron-left"] = "rbxassetid://7733717651",
    ["flask-conical"] = "rbxassetid://7733798901",
    ["wallet"] = "rbxassetid://7743877573",
    ["euro"] = "rbxassetid://7733771891",
    ["trash-2"] = "rbxassetid://7743873772",
    ["check-circle"] = "rbxassetid://7733919427",
    ["layout"] = "rbxassetid://7733970543",
    ["droplets"] = "rbxassetid://7733771078",
    ["align-start-vertical"] = "rbxassetid://8997382085",
    ["rotate-cw"] = "rbxassetid://7734051957",
    ["minimize"] = "rbxassetid://7733997941",
    ["arrow-down-left"] = "rbxassetid://7733672282",
    ["signal-medium"] = "rbxassetid://8997387319",
    ["align-vertical-distribute-center"] = "rbxassetid://8997382212",
    ["image-off"] = "rbxassetid://7733963907",
    ["cloudy"] = "rbxassetid://7733747106",
    ["align-left"] = "rbxassetid://7733911357",
    ["film"] = "rbxassetid://7733942579",
    ["chevrons-down"] = "rbxassetid://7733720604",
    ["pointer"] = "rbxassetid://7734042307",
    ["folder"] = "rbxassetid://7733799185",
    ["chevrons-left"] = "rbxassetid://7733720701",
    ["shield-off"] = "rbxassetid://7734056540",
    ["wrench"] = "rbxassetid://7743878358"
}

local Theme = {
    TotalBlack = Color3.fromRGB(0, 0, 0),
    Background = Color3.fromRGB(8, 8, 8),
    TopBar = Color3.fromRGB(12, 12, 12),
    Sidebar = Color3.fromRGB(10, 10, 10),
    ContentBg = Color3.fromRGB(8, 8, 8),
    DarkGray = Color3.fromRGB(25, 25, 25),
    Gray = Color3.fromRGB(40, 40, 40),
    LightGray = Color3.fromRGB(60, 60, 60),
    Border = Color3.fromRGB(35, 35, 35),
    Green = Color3.fromRGB(0, 255, 0),
    GreenDark = Color3.fromRGB(0, 200, 0),
    White = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(180, 180, 180),
}

local APTX = {}
APTX.__index = APTX

APTX.Sections = {}
APTX.CurrentSection = nil
APTX.DevMode = false
APTX.Title = "APTX"
APTX.Draggable = true
APTX.GUI = nil
APTX.MainFrame = nil
APTX.HideButton = nil
APTX.IsVisible = true

local function log(...)
    if APTX.DevMode then
        print("[APTX]", ...)
    end
end

local function createCorner(radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    return corner
end

local function createStroke(color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return stroke
end

local function tween(object, properties, duration)
    local info = TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(object, info, properties):Play()
end

local function createIcon(parent, iconName, size)
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, size or 18, 0, size or 18)
    icon.BackgroundTransparency = 1
    icon.ImageColor3 = Theme.White
    icon.Image = Icons[iconName] or ""
    icon.Parent = parent
    return icon
end

function APTX:Config(title, draggable, devmode)
    APTX.Title = title or "APTX GUI"
    APTX.Draggable = draggable ~= false
    APTX.DevMode = devmode == true
    
    log("Inicializando APTX GUI...")
    log("Título:", APTX.Title)
    log("Draggable:", APTX.Draggable)
    log("DevMode:", APTX.DevMode)
    
    APTX:CreateGUI()
    APTX:CreateHideButton()
    
    log("GUI creado exitosamente")
    return APTX
end

function APTX:CreateGUI()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    if playerGui:FindFirstChild("APTXGui") then
        playerGui.APTXGui:Destroy()
        log("GUI anterior eliminado")
    end
    
    APTX.GUI = Instance.new("ScreenGui")
    APTX.GUI.Name = "APTXGui"
    APTX.GUI.ResetOnSpawn = false
    APTX.GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    APTX.GUI.Parent = playerGui
    
    APTX.MainFrame = Instance.new("Frame")
    APTX.MainFrame.Name = "MainFrame"
    APTX.MainFrame.Size = UDim2.new(0, 539, 0, 353)
    APTX.MainFrame.Position = UDim2.new(0.5, -270, 0.5, -177)
    APTX.MainFrame.BackgroundColor3 = Theme.Background
    APTX.MainFrame.BorderSizePixel = 0
    APTX.MainFrame.Parent = APTX.GUI
    
    createCorner(10).Parent = APTX.MainFrame
    createStroke(Theme.Border, 2).Parent = APTX.MainFrame
    
    APTX:CreateTopBar()
    
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(1, 0, 1, -40)
    container.Position = UDim2.new(0, 0, 0, 40)
    container.BackgroundTransparency = 1
    container.Parent = APTX.MainFrame
    
    APTX:CreateSidebar(container)
    APTX:CreateContentArea(container)
    
    if APTX.Draggable then
        APTX:MakeDraggable()
        log("GUI draggable activado")
    end
end

function APTX:CreateTopBar()
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 40)
    topBar.BackgroundColor3 = Theme.TopBar
    topBar.BorderSizePixel = 0
    topBar.Parent = APTX.MainFrame
    
    createCorner(10).Parent = topBar
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -50, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = APTX.Title
    title.TextColor3 = Theme.White
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = topBar
    
    
    APTX.TopBar = topBar
end

function APTX:CreateSidebar(parent)
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0.25, -5, 1, 0)
    sidebar.BackgroundColor3 = Theme.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.Parent = parent
    
    createCorner(8).Parent = sidebar
    
    local sectionList = Instance.new("ScrollingFrame")
    sectionList.Name = "SectionList"
    sectionList.Size = UDim2.new(1, -10, 1, -10)
    sectionList.Position = UDim2.new(0, 5, 0, 5)
    sectionList.BackgroundTransparency = 1
    sectionList.BorderSizePixel = 0
    sectionList.ScrollBarThickness = 3
    sectionList.ScrollBarImageColor3 = Theme.Border
    sectionList.CanvasSize = UDim2.new(0, 0, 0, 0)
    sectionList.Parent = sidebar
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)
    layout.Parent = sectionList
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sectionList.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)
    
    APTX.SectionList = sectionList
end

function APTX:CreateContentArea(parent)
    local content = Instance.new("Frame")
    content.Name = "ContentArea"
    content.Size = UDim2.new(0.75, -5, 1, 0)
    content.Position = UDim2.new(0.25, 5, 0, 0)
    content.BackgroundColor3 = Theme.ContentBg
    content.BorderSizePixel = 0
    content.Parent = parent
    
    createCorner(8).Parent = content
    createStroke(Theme.Border, 1).Parent = content
    
    APTX.ContentArea = content
end

function APTX:CreateHideButton()
    local hideBtn = Instance.new("TextButton")
    hideBtn.Name = "HideButton"
    hideBtn.Size = UDim2.new(0, 45, 0, 45)
    hideBtn.Position = UDim2.new(0, 15, 0, 15)
    hideBtn.BackgroundColor3 = Theme.TopBar
    hideBtn.BorderSizePixel = 0
    hideBtn.Text = ""
    hideBtn.Parent = APTX.GUI
    
    createCorner(8).Parent = hideBtn
    createStroke(Theme.Border, 2).Parent = hideBtn
    
    createIcon(hideBtn, "menu", 24).Position = UDim2.new(0.5, -12, 0.5, -12)
    
    hideBtn.MouseButton1Click:Connect(function()
        APTX:ToggleVisibility()
    end)
    
    hideBtn.MouseEnter:Connect(function()
        tween(hideBtn, {BackgroundColor3 = Theme.Gray})
    end)
    
    hideBtn.MouseLeave:Connect(function()
        tween(hideBtn, {BackgroundColor3 = Theme.TopBar})
    end)
    
    APTX.HideButton = hideBtn
end

function APTX:ToggleVisibility()
    APTX.IsVisible = not APTX.IsVisible
    log("Visibilidad:", APTX.IsVisible)
    
    tween(APTX.MainFrame, {
        Position = APTX.IsVisible 
            and UDim2.new(0.5, -270, 0.5, -177) 
            or UDim2.new(0.5, -270, 1.5, 0)
    }, 0.3)
end

function APTX:MakeDraggable()
    local dragging = false
    local dragInput, dragStart, startPos
    
    APTX.TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = APTX.MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    APTX.TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            APTX.MainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function APTX:Destroy()
    if APTX.GUI then
        APTX.GUI:Destroy()
        log("GUI destruido")
    end
end

function APTX:Section(text, icon, default)
    log("Creando sección:", text)
    
    local section = {
        Name = text,
        Icon = icon,
        Container = nil,
        Button = nil,
    }
    
    section.Button = Instance.new("TextButton")
    section.Button.Name = text
    section.Button.Size = UDim2.new(1, 0, 0, 36)
    section.Button.BackgroundColor3 = Theme.DarkGray
    section.Button.Text = ""
    section.Button.Parent = APTX.SectionList
    
    createCorner(6).Parent = section.Button
    
    if icon then
        local iconImg = createIcon(section.Button, icon, 18)
        iconImg.Position = UDim2.new(0, 8, 0.5, -9)
    end
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -40, 1, 0)
    label.Position = UDim2.new(0, 32, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.TextSecondary
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = section.Button
    
    section.Container = Instance.new("ScrollingFrame")
    section.Container.Name = text .. "_Container"
    section.Container.Size = UDim2.new(1, -15, 1, -15)
    section.Container.Position = UDim2.new(0, 8, 0, 8)
    section.Container.BackgroundTransparency = 1
    section.Container.BorderSizePixel = 0
    section.Container.ScrollBarThickness = 3
    section.Container.ScrollBarImageColor3 = Theme.Border
    section.Container.Visible = false
    section.Container.CanvasSize = UDim2.new(0, 0, 0, 0)
    section.Container.Parent = APTX.ContentArea
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = section.Container
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        section.Container.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)
    
    section.Button.MouseButton1Click:Connect(function()
        APTX:SelectSection(text)
    end)
    
    section.Button.MouseEnter:Connect(function()
        if APTX.CurrentSection ~= text then
            tween(section.Button, {BackgroundColor3 = Theme.Gray})
        end
    end)
    
    section.Button.MouseLeave:Connect(function()
        if APTX.CurrentSection ~= text then
            tween(section.Button, {BackgroundColor3 = Theme.DarkGray})
        end
    end)
    
    table.insert(APTX.Sections, section)
    
    if default == true or #APTX.Sections == 1 then
        APTX:SelectSection(text)
    end
    
    return text
end

function APTX:SelectSection(name)
    log("Seleccionando sección:", name)
    
    for _, section in ipairs(APTX.Sections) do
        if section.Name == name then
            section.Container.Visible = true
            section.Button.BackgroundColor3 = Theme.Green
            section.Button.Label.TextColor3 = Theme.TotalBlack
            if section.Button:FindFirstChild("Icon") then
                section.Button.Icon.ImageColor3 = Theme.TotalBlack
            end
            APTX.CurrentSection = name
        else
            section.Container.Visible = false
            section.Button.BackgroundColor3 = Theme.DarkGray
            section.Button.Label.TextColor3 = Theme.TextSecondary
            if section.Button:FindFirstChild("Icon") then
                section.Button.Icon.ImageColor3 = Theme.White
            end
        end
    end
end

function APTX:GetSection(name)
    for _, section in ipairs(APTX.Sections) do
        if section.Name == name then
            return section
        end
    end
    return nil
end

function APTX:Button(sectionName, text, icon, callback)
    local section = APTX:GetSection(sectionName)
    if not section then 
        log("ERROR: Sección no encontrada:", sectionName)
        return 
    end
    
    log("Creando botón:", text, "en sección:", sectionName)
    
    local button = Instance.new("TextButton")
    button.Name = text
    button.Size = UDim2.new(1, 0, 0, 34)
    button.BackgroundColor3 = Theme.DarkGray
    button.Text = ""
    button.Parent = section.Container
    
    createCorner(6).Parent = button
    
    if icon then
        local iconImg = createIcon(button, icon, 16)
        iconImg.Position = UDim2.new(0, 8, 0.5, -8)
    end
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Position = UDim2.new(0, icon and 30 or 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.White
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = button
    
    button.MouseButton1Click:Connect(function()
        log("Click en botón:", text)
        tween(button, {BackgroundColor3 = Theme.Green}, 0.1)
        wait(0.15)
        tween(button, {BackgroundColor3 = Theme.Gray}, 0.1)
        if callback then callback() end
    end)
    
    button.MouseEnter:Connect(function()
        tween(button, {BackgroundColor3 = Theme.Gray})
    end)
    
    button.MouseLeave:Connect(function()
        tween(button, {BackgroundColor3 = Theme.DarkGray})
    end)
    
    return button
end

function APTX:Toggle(sectionName, text, icon, default, callback)
    local section = APTX:GetSection(sectionName)
    if not section then 
        log("ERROR: Sección no encontrada:", sectionName)
        return 
    end
    
    log("Creando toggle:", text)
    
    local isOn = default == true
    
    local container = Instance.new("Frame")
    container.Name = text
    container.Size = UDim2.new(1, 0, 0, 34)
    container.BackgroundColor3 = Theme.DarkGray
    container.Parent = section.Container
    
    createCorner(6).Parent = container
    
    if icon then
        local iconImg = createIcon(container, icon, 16)
        iconImg.Position = UDim2.new(0, 8, 0.5, -8)
    end
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -90, 1, 0)
    label.Position = UDim2.new(0, icon and 30 or 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.White
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleSwitch"
    toggleBtn.Size = UDim2.new(0, 42, 0, 22)
    toggleBtn.Position = UDim2.new(1, -48, 0.5, -11)
    toggleBtn.BackgroundColor3 = isOn and Theme.Green or Theme.Gray
    toggleBtn.Text = ""
    toggleBtn.Parent = container
    
    createCorner(11).Parent = toggleBtn
    
    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(0, 18, 0, 18)
    indicator.Position = isOn and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    indicator.BackgroundColor3 = Theme.White
    indicator.Parent = toggleBtn
    
    createCorner(9).Parent = indicator
    
    toggleBtn.MouseButton1Click:Connect(function()
        isOn = not isOn
        log("Toggle:", text, "=", isOn)
        
        tween(indicator, {
            Position = isOn and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        })
        tween(toggleBtn, {
            BackgroundColor3 = isOn and Theme.Green or Theme.Gray
        })
        
        if callback then callback(isOn) end
    end)
    
    return container
end

function APTX:Slider(sectionName, text, icon, min, max, default, callback)
    local section = APTX:GetSection(sectionName)
    if not section then 
        log("ERROR: Sección no encontrada:", sectionName)
        return 
    end
    
    log("Creando slider:", text)
    
    local value = default or min
    
    local container = Instance.new("Frame")
    container.Name = text
    container.Size = UDim2.new(1, 0, 0, 50)
    container.BackgroundColor3 = Theme.DarkGray
    container.Parent = section.Container
    
    createCorner(6).Parent = container
    
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 20)
    header.Position = UDim2.new(0, 0, 0, 5)
    header.BackgroundTransparency = 1
    header.Parent = container
    
    if icon then
        local iconImg = createIcon(header, icon, 16)
        iconImg.Position = UDim2.new(0, 8, 0.5, -8)
    end
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -100, 1, 0)
    label.Position = UDim2.new(0, icon and 30 or 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.White
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = header
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 60, 1, 0)
    valueLabel.Position = UDim2.new(1, -65, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(value)
    valueLabel.TextColor3 = Theme.Green
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 13
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = header
    
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(1, -16, 0, 8)
    track.Position = UDim2.new(0, 8, 1, -15)
    track.BackgroundColor3 = Theme.Gray
    track.Parent = container
    
    createCorner(4).Parent = track
    
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Green
    fill.BorderSizePixel = 0
    fill.Parent = track
    
    createCorner(4).Parent = fill
    
    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new((value - min) / (max - min), -8, 0.5, -8)
    knob.BackgroundColor3 = Theme.White
    knob.BorderSizePixel = 0
    knob.Parent = track
    
    createCorner(8).Parent = knob
    
    local dragging = false
    
    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max - min) * pos)
        valueLabel.Text = tostring(value)
        
        fill.Size = UDim2.new(pos, 0, 1, 0)
        knob.Position = UDim2.new(pos, -8, 0.5, -8)
        
        if callback then callback(value) end
    end
    
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
        end
    end)
    
    track.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)
    
    return container
end

function APTX:Menu(sectionName, text, placeholder, icon, options, default, callback)
    local section = APTX:GetSection(sectionName)
    if not section then 
        log("ERROR: Sección no encontrada:", sectionName)
        return 
    end
    
    log("Creando menú:", text)
    
    local isOpen = false
    local selected = default or options[1]
    
    local container = Instance.new("Frame")
    container.Name = text
    container.Size = UDim2.new(1, 0, 0, 60)
    container.BackgroundColor3 = Theme.DarkGray
    container.ClipsDescendants = true
    container.Parent = section.Container
    
    createCorner(6).Parent = container
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 18)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.White
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local dropBtn = Instance.new("TextButton")
    dropBtn.Size = UDim2.new(1, -20, 0, 28)
    dropBtn.Position = UDim2.new(0, 10, 0, 27)
    dropBtn.BackgroundColor3 = Theme.Gray
    dropBtn.Text = ""
    dropBtn.Parent = container
    
    createCorner(5).Parent = dropBtn
    
    if icon then
        local iconImg = createIcon(dropBtn, icon, 14)
        iconImg.Position = UDim2.new(0, 6, 0.5, -7)
    end
    
    local selectedLabel = Instance.new("TextLabel")
    selectedLabel.Size = UDim2.new(1, -50, 1, 0)
    selectedLabel.Position = UDim2.new(0, icon and 26 or 8, 0, 0)
    selectedLabel.BackgroundTransparency = 1
    selectedLabel.Text = selected
    selectedLabel.TextColor3 = Theme.White
    selectedLabel.Font = Enum.Font.Gotham
    selectedLabel.TextSize = 12
    selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
    selectedLabel.Parent = dropBtn
    
    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -22, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = Theme.White
    arrow.Font = Enum.Font.Gotham
    arrow.TextSize = 10
    arrow.Parent = dropBtn
    
    local optionsList = Instance.new("Frame")
    optionsList.Name = "OptionsList"
    optionsList.Size = UDim2.new(1, -20, 0, 0)
    optionsList.Position = UDim2.new(0, 10, 0, 60)
    optionsList.BackgroundColor3 = Theme.Gray
    optionsList.BorderSizePixel = 0
    optionsList.ClipsDescendants = true
    optionsList.Parent = container
    
    createCorner(5).Parent = optionsList
    createStroke(Theme.Border, 1).Parent = optionsList
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = optionsList
    
    for _, option in ipairs(options) do
        local optionBtn = Instance.new("TextButton")
        optionBtn.Size = UDim2.new(1, 0, 0, 26)
        optionBtn.BackgroundColor3 = Theme.Gray
        optionBtn.Text = "  " .. option
        optionBtn.TextColor3 = Theme.White
        optionBtn.Font = Enum.Font.Gotham
        optionBtn.TextSize = 12
        optionBtn.TextXAlignment = Enum.TextXAlignment.Left
        optionBtn.Parent = optionsList
        
        optionBtn.MouseButton1Click:Connect(function()
            selected = option
            selectedLabel.Text = selected
            log("Menú selección:", option)
            
            if callback then callback(selected) end
            
            isOpen = false
            tween(container, {Size = UDim2.new(1, 0, 0, 60)}, 0.2)
            tween(optionsList, {Size = UDim2.new(1, -20, 0, 0)}, 0.2)
            tween(arrow, {Rotation = 0}, 0.2)
        end)
        
        optionBtn.MouseEnter:Connect(function()
            tween(optionBtn, {BackgroundColor3 = Theme.LightGray})
        end)
        
        optionBtn.MouseLeave:Connect(function()
            tween(optionBtn, {BackgroundColor3 = Theme.Gray})
        end)
    end
    
    dropBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        local targetHeight = isOpen and (60 + #options * 26 + 5) or 60
        local listHeight = isOpen and (#options * 26) or 0
        
        tween(container, {Size = UDim2.new(1, 0, 0, targetHeight)}, 0.2)
        tween(optionsList, {Size = UDim2.new(1, -20, 0, listHeight)}, 0.2)
        tween(arrow, {Rotation = isOpen and 180 or 0}, 0.2)
    end)
    
    return container
end

function APTX:Input(sectionName, text, icon, placeholder, callback)
    local section = APTX:GetSection(sectionName)
    if not section then 
        log("ERROR: Sección no encontrada:", sectionName)
        return 
    end
    
    log("Creando input:", text)
    
    local container = Instance.new("Frame")
    container.Name = text
    container.Size = UDim2.new(1, 0, 0, 60)
    container.BackgroundColor3 = Theme.DarkGray
    container.Parent = section.Container
    
    createCorner(6).Parent = container
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 18)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.White
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(1, -20, 0, 28)
    inputBox.Position = UDim2.new(0, 10, 0, 27)
    inputBox.BackgroundColor3 = Theme.Gray
    inputBox.PlaceholderText = placeholder or ""
    inputBox.PlaceholderColor3 = Theme.TextSecondary
    inputBox.Text = ""
    inputBox.TextColor3 = Theme.White
    inputBox.Font = Enum.Font.Gotham
    inputBox.TextSize = 12
    inputBox.TextXAlignment = Enum.TextXAlignment.Left
    inputBox.ClearTextOnFocus = false
    inputBox.Parent = container
    
    createCorner(5).Parent = inputBox
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 8)
    padding.Parent = inputBox
    
    inputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed and callback then
            log("Input:", text, "=", inputBox.Text)
            callback(inputBox.Text)
        end
    end)
    
    return inputBox
end

function APTX:Label(sectionName, text)
    local section = APTX:GetSection(sectionName)
    if not section then 
        log("ERROR: Sección no encontrada:", sectionName)
        return 
    end
    
    local label = Instance.new("TextLabel")
    label.Name = text
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.TextSecondary
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.Parent = section.Container
    
    return label
end

-- ══════════════════════════════════════════════════════════════
--  APTX:Notify  —  Sistema de notificaciones integrado
-- ══════════════════════════════════════════════════════════════

local RunService_N   = game:GetService("RunService")
local UserInputSvc_N = game:GetService("UserInputService")

local _NeonPalettes = {
	warning = { Color3.fromRGB(255, 210, 0),  Color3.fromRGB(255, 120, 0)   },
	success = { Color3.fromRGB(0,   255, 110), Color3.fromRGB(0,   200, 50)  },
	error   = { Color3.fromRGB(255, 40,  40),  Color3.fromRGB(255, 0,   130) },
	neutral = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(160, 160, 255) },
}

local function _ntw(obj, props, t, style, dir)
	local info = TweenInfo.new(t or 0.25, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
	TweenService:Create(obj, info, props):Play()
end

local function _nCorner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 10)
	c.Parent = parent
end

local function _nStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(60, 60, 60)
	s.Thickness = thickness or 1.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
end

local function _buildNeon(card, notifType)
	local pal = _NeonPalettes[notifType] or _NeonPalettes.neutral
	local c1, c2 = pal[1], pal[2]
	local ns = Instance.new("UIStroke")
	ns.Thickness = 2.5
	ns.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ns.Color  = c1
	ns.Parent = card
	local t = 0
	local conn = RunService_N.Heartbeat:Connect(function(dt)
		t = (t + dt * 1.4) % 1
		ns.Color = c1:Lerp(c2, math.abs(math.sin(t * math.pi)))
	end)
	return conn
end

local N_SCALE    = 0.85
local N_W        = math.floor(320 * N_SCALE)
local N_TOPBAR_H = math.floor(38  * N_SCALE)
local N_BODY_H   = math.floor(80  * N_SCALE)
local N_BTN_H    = math.floor(48  * N_SCALE)
local N_PAD      = math.floor(14  * N_SCALE)
local N_BTN_W    = math.floor(120 * N_SCALE)
local N_BTN_SZ   = math.floor(30  * N_SCALE)
local N_ICON_SZ  = math.floor(36  * N_SCALE)
local N_AVA_SZ   = math.floor(20  * N_SCALE)

local NC = {
	BG      = Color3.fromRGB(0,   0,   0),
	TOPBAR  = Color3.fromRGB(10,  10,  10),
	DIVIDER = Color3.fromRGB(65,  65,  70),
	ACCENT  = Color3.fromRGB(88,  101, 242),
	NEUTRAL = Color3.fromRGB(72,  72,  80),
	TXT_PRI = Color3.fromRGB(245, 245, 255),
	TXT_SEC = Color3.fromRGB(175, 175, 185),
	CLOSEBG = Color3.fromRGB(45,  45,  50),
	DECLINE = Color3.fromRGB(237, 66,  69),
}

function APTX:Notify(params)
	assert(type(params) == "table",  "[APTX:Notify] params debe ser una tabla")
	assert(params.title,             "[APTX:Notify] params.title es requerido")
	assert(params.content,           "[APTX:Notify] params.content es requerido")

	local title     = params.title
	local body      = params.content
	local iconTop   = params["topbar-icon"]
	local iconBody  = params["content-icon"]
	local duration  = params.duration
	local sound     = params.sound
	local buttons   = params.buttons
	local notifType = params.type or "neutral"

	local hasIconTop  = iconTop  ~= nil and iconTop  ~= ""
	local hasIconBody = iconBody ~= nil and iconBody ~= ""
	local hasButtons  = buttons  ~= nil and #buttons  > 0
	local hasDuration = duration ~= nil and duration  > 0

	local BODY_ACTUAL = hasIconBody and N_BODY_H or math.floor(60 * N_SCALE)
	local BTN_ACTUAL  = hasButtons  and N_BTN_H  or 0
	local CARD_H      = N_TOPBAR_H + BODY_ACTUAL + 2 + BTN_ACTUAL + (hasButtons and 0 or math.floor(6 * N_SCALE))

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local SG = Instance.new("ScreenGui")
	SG.Name           = "APTX_Notify_" .. tostring(tick())
	SG.ResetOnSpawn   = false
	SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	SG.Parent         = playerGui

	local Card = Instance.new("Frame")
	Card.Name              = "Card"
	Card.Size              = UDim2.new(0, N_W, 0, CARD_H)
	Card.Position          = UDim2.new(1, N_W + 20, 1, -(CARD_H + 16))
	Card.BackgroundColor3  = NC.BG
	Card.BorderSizePixel   = 0
	Card.ClipsDescendants  = true
	Card.Parent            = SG
	_nCorner(Card, 13)

	local neonConn = _buildNeon(Card, notifType)

	local TB = Instance.new("Frame")
	TB.Name             = "TopBar"
	TB.Size             = UDim2.new(1, 0, 0, N_TOPBAR_H)
	TB.BackgroundColor3 = NC.TOPBAR
	TB.BorderSizePixel  = 0
	TB.ZIndex           = 2
	TB.Parent           = Card
	_nCorner(TB, 13)

	local TBpatch = Instance.new("Frame")
	TBpatch.Size             = UDim2.new(1, 0, 0, 14)
	TBpatch.Position         = UDim2.new(0, 0, 1, -14)
	TBpatch.BackgroundColor3 = NC.TOPBAR
	TBpatch.BorderSizePixel  = 0
	TBpatch.ZIndex           = 2
	TBpatch.Parent           = TB

	local AccLine = Instance.new("Frame")
	AccLine.Size             = UDim2.new(0, 3, 1, 0)
	AccLine.BackgroundColor3 = NC.ACCENT
	AccLine.BorderSizePixel  = 0
	AccLine.ZIndex           = 3
	AccLine.Parent           = TB
	_nCorner(AccLine, 2)

	local AvaImg
	local titleOffsetX = N_PAD + 6

	if hasIconTop then
		local AvaFrame = Instance.new("Frame")
		AvaFrame.Size             = UDim2.new(0, N_AVA_SZ, 0, N_AVA_SZ)
		AvaFrame.Position         = UDim2.new(0, N_PAD - 2, 0.5, 0)
		AvaFrame.AnchorPoint      = Vector2.new(0, 0.5)
		AvaFrame.BackgroundColor3 = NC.ACCENT
		AvaFrame.BorderSizePixel  = 0
		AvaFrame.ZIndex           = 3
		AvaFrame.Parent           = TB
		_nCorner(AvaFrame, 99)

		AvaImg = Instance.new("ImageLabel")
		AvaImg.Size                   = UDim2.new(1, 0, 1, 0)
		AvaImg.BackgroundTransparency = 1
		AvaImg.Image                  = iconTop
		AvaImg.ScaleType              = Enum.ScaleType.Crop
		AvaImg.ZIndex                 = 4
		AvaImg.Parent                 = AvaFrame
		_nCorner(AvaImg, 99)

		titleOffsetX = N_AVA_SZ + N_PAD + 8
	end

	local TitleLbl = Instance.new("TextLabel")
	TitleLbl.Size                   = UDim2.new(1, -(titleOffsetX + 34), 1, 0)
	TitleLbl.Position               = UDim2.new(0, titleOffsetX, 0, 0)
	TitleLbl.BackgroundTransparency = 1
	TitleLbl.Text                   = title
	TitleLbl.Font                   = Enum.Font.GothamBold
	TitleLbl.TextSize               = math.floor(12 * N_SCALE)
	TitleLbl.TextColor3             = NC.TXT_PRI
	TitleLbl.TextXAlignment         = Enum.TextXAlignment.Left
	TitleLbl.TextTruncate           = Enum.TextTruncate.AtEnd
	TitleLbl.ZIndex                 = 3
	TitleLbl.Parent                 = TB

	local CloseBtn = Instance.new("ImageButton")
	CloseBtn.Size             = UDim2.new(0, math.floor(24 * N_SCALE), 0, math.floor(24 * N_SCALE))
	CloseBtn.Position         = UDim2.new(1, -math.floor(30 * N_SCALE), 0.5, 0)
	CloseBtn.AnchorPoint      = Vector2.new(0, 0.5)
	CloseBtn.BackgroundColor3 = NC.CLOSEBG
	CloseBtn.Image            = "rbxassetid://7072725342"
	CloseBtn.ImageColor3      = Color3.fromRGB(190, 190, 200)
	CloseBtn.ScaleType        = Enum.ScaleType.Fit
	CloseBtn.BorderSizePixel  = 0
	CloseBtn.AutoButtonColor  = false
	CloseBtn.ZIndex           = 4
	CloseBtn.Parent           = TB
	_nCorner(CloseBtn, 99)

	CloseBtn.MouseEnter:Connect(function()
		_ntw(CloseBtn, {BackgroundColor3 = NC.DECLINE}, 0.15)
	end)
	CloseBtn.MouseLeave:Connect(function()
		_ntw(CloseBtn, {BackgroundColor3 = NC.CLOSEBG}, 0.15)
	end)

	local DivTop = Instance.new("Frame")
	DivTop.Size             = UDim2.new(1, 0, 0, 1)
	DivTop.Position         = UDim2.new(0, 0, 0, N_TOPBAR_H)
	DivTop.BackgroundColor3 = NC.DIVIDER
	DivTop.BorderSizePixel  = 0
	DivTop.ZIndex           = 2
	DivTop.Parent           = Card

	local Body = Instance.new("Frame")
	Body.Size                   = UDim2.new(1, 0, 0, BODY_ACTUAL)
	Body.Position               = UDim2.new(0, 0, 0, N_TOPBAR_H + 1)
	Body.BackgroundTransparency = 1
	Body.ZIndex                 = 2
	Body.Parent                 = Card

	local IconFrame, IconImg
	local msgOffsetX = N_PAD

	if hasIconBody then
		IconFrame = Instance.new("Frame")
		IconFrame.Size             = UDim2.new(0, N_ICON_SZ, 0, N_ICON_SZ)
		IconFrame.Position         = UDim2.new(0, N_PAD, 0.5, 0)
		IconFrame.AnchorPoint      = Vector2.new(0, 0.5)
		IconFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
		IconFrame.BorderSizePixel  = 0
		IconFrame.ZIndex           = 3
		IconFrame.Parent           = Body
		_nCorner(IconFrame, 10)
		_nStroke(IconFrame, NC.ACCENT, 1)

		IconImg = Instance.new("ImageLabel")
		IconImg.Size                   = UDim2.new(0.62, 0, 0.62, 0)
		IconImg.AnchorPoint            = Vector2.new(0.5, 0.5)
		IconImg.Position               = UDim2.new(0.5, 0, 0.5, 0)
		IconImg.BackgroundTransparency = 1
		IconImg.Image                  = iconBody
		IconImg.ImageColor3            = NC.ACCENT
		IconImg.ZIndex                 = 4
		IconImg.Parent                 = IconFrame

		msgOffsetX = N_ICON_SZ + N_PAD + 8
	end

	local MsgLbl = Instance.new("TextLabel")
	MsgLbl.Size                   = UDim2.new(1, -(msgOffsetX + N_PAD), 1, -10)
	MsgLbl.Position               = UDim2.new(0, msgOffsetX, 0, 5)
	MsgLbl.BackgroundTransparency = 1
	MsgLbl.Text                   = body
	MsgLbl.Font                   = Enum.Font.Gotham
	MsgLbl.TextSize               = math.floor(11 * N_SCALE)
	MsgLbl.TextColor3             = NC.TXT_SEC
	MsgLbl.TextWrapped            = true
	MsgLbl.TextXAlignment         = Enum.TextXAlignment.Left
	MsgLbl.TextYAlignment         = Enum.TextYAlignment.Top
	MsgLbl.ZIndex                 = 3
	MsgLbl.Parent                 = Body

	local DividerFill
	if hasButtons or hasDuration then
		local DividerBG = Instance.new("Frame")
		DividerBG.Size             = UDim2.new(1, 0, 0, 2)
		DividerBG.Position         = UDim2.new(0, 0, 0, N_TOPBAR_H + 1 + BODY_ACTUAL)
		DividerBG.BackgroundColor3 = NC.DIVIDER
		DividerBG.BorderSizePixel  = 0
		DividerBG.ZIndex           = 3
		DividerBG.ClipsDescendants = true
		DividerBG.Parent           = Card

		DividerFill = Instance.new("Frame")
		DividerFill.Size             = UDim2.new(1, 0, 1, 0)
		DividerFill.BackgroundColor3 = NC.ACCENT
		DividerFill.BorderSizePixel  = 0
		DividerFill.ZIndex           = 4
		DividerFill.Parent           = DividerBG
	end

	local createdBtns = {}
	if hasButtons then
		local BtnContainer = Instance.new("Frame")
		BtnContainer.Size                   = UDim2.new(1, 0, 0, BTN_ACTUAL)
		BtnContainer.Position               = UDim2.new(0, 0, 0, N_TOPBAR_H + 1 + BODY_ACTUAL + 2)
		BtnContainer.BackgroundTransparency = 1
		BtnContainer.ZIndex                 = 3
		BtnContainer.Parent                 = Card

		local BtnLayout = Instance.new("UIListLayout")
		BtnLayout.FillDirection       = Enum.FillDirection.Horizontal
		BtnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		BtnLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
		BtnLayout.Padding             = UDim.new(0, math.floor(8 * N_SCALE))
		BtnLayout.Parent              = BtnContainer

		for i, bDef in ipairs(buttons) do
			if i > 3 then break end
			local bg = bDef.color or NC.NEUTRAL
			local Btn = Instance.new("TextButton")
			Btn.Size             = UDim2.new(0, N_BTN_W, 0, N_BTN_SZ)
			Btn.BackgroundColor3 = bg
			Btn.Text             = bDef.label or ("Botón " .. i)
			Btn.Font             = Enum.Font.GothamBold
			Btn.TextSize         = math.floor(11 * N_SCALE)
			Btn.TextColor3       = Color3.fromRGB(255, 255, 255)
			Btn.BorderSizePixel  = 0
			Btn.AutoButtonColor  = false
			Btn.ZIndex           = 4
			Btn.Parent           = BtnContainer
			_nCorner(Btn, 7)

			local bs = Instance.new("UIStroke")
			bs.Color        = Color3.new(1, 1, 1)
			bs.Transparency = 0.88
			bs.Thickness    = 1
			bs.Parent       = Btn

			local hoverColor = bg:Lerp(Color3.new(1, 1, 1), 0.18)
			Btn.MouseEnter:Connect(function()
				_ntw(Btn, {BackgroundColor3 = hoverColor}, 0.13)
			end)
			Btn.MouseLeave:Connect(function()
				_ntw(Btn, {BackgroundColor3 = bg}, 0.13)
			end)
			Btn.MouseButton1Down:Connect(function()
				_ntw(Btn, {Size = UDim2.new(0, N_BTN_W - 4, 0, N_BTN_SZ - 3)}, 0.09, Enum.EasingStyle.Quad)
			end)
			Btn.MouseButton1Up:Connect(function()
				_ntw(Btn, {Size = UDim2.new(0, N_BTN_W, 0, N_BTN_SZ)}, 0.14, Enum.EasingStyle.Back)
			end)
			Btn.MouseButton1Click:Connect(function()
				if bDef.callback then task.spawn(bDef.callback) end
			end)
			createdBtns[i] = Btn
		end
	end

	if sound then
		local snd = Instance.new("Sound")
		snd.SoundId = sound
		snd.Volume  = 0.6
		snd.Parent  = SG
		snd:Play()
		game:GetService("Debris"):AddItem(snd, 5)
	end

	local dragging, dragInput, dragStart, startPos
	TB.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging  = true
			dragStart = inp.Position
			startPos  = Card.Position
			inp.Changed:Connect(function()
				if inp.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	TB.InputChanged:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = inp
		end
	end)
	UserInputSvc_N.InputChanged:Connect(function(inp)
		if inp == dragInput and dragging then
			local d = inp.Position - dragStart
			Card.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end
	end)

	local Notif         = {}
	Notif._sg           = SG
	Notif._card         = Card
	Notif._title        = TitleLbl
	Notif._msg          = MsgLbl
	Notif._avaImg       = AvaImg
	Notif._bodyIcon     = IconImg
	Notif._divFill      = DividerFill
	Notif._neonConn     = neonConn
	Notif._alive        = true
	Notif._buttons      = createdBtns
	Notif._accLine      = AccLine
	Notif._iconFrame    = IconFrame

	local function fallClose(cb)
		if not Notif._alive then return end
		Notif._alive = false
		local cur = Card.Position

		_ntw(Card, {
			Position = UDim2.new(cur.X.Scale, cur.X.Offset, cur.Y.Scale, cur.Y.Offset - math.floor(12 * N_SCALE)),
			Rotation = -2,
		}, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		task.wait(0.17)

		_ntw(Card, {
			Position = UDim2.new(1, N_W + 80, cur.Y.Scale, cur.Y.Offset + math.floor(CARD_H * 0.55)),
			Rotation = 22,
		}, 0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

		_ntw(Card, {BackgroundTransparency = 0.5}, 0.35, Enum.EasingStyle.Linear)

		task.delay(0.46, function()
			neonConn:Disconnect()
			if cb then pcall(cb) end
			SG:Destroy()
		end)
	end

	task.delay(0.05, function()
		_ntw(Card,
			{Position = UDim2.new(1, -(N_W + 16), 1, -(CARD_H + 16))},
			0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out
		)
	end)

	if hasDuration and DividerFill then
		_ntw(DividerFill, {Size = UDim2.new(0, 0, 1, 0)}, duration, Enum.EasingStyle.Linear)
		task.delay(duration, function()
			if Notif._alive then fallClose() end
		end)
	end

	CloseBtn.MouseButton1Click:Connect(function()
		if Notif._alive then fallClose() end
	end)

	function Notif:Destroy()
		if not self._alive then return end
		fallClose()
	end

	function Notif:Close(callback)
		if not self._alive then return end
		fallClose(callback)
	end

	function Notif:Edit(p)
		if not self._alive then return end
		p = p or {}
		if p.title   then self._title.Text = p.title   end
		if p.content then self._msg.Text   = p.content end
		if p["topbar-icon"]  and self._avaImg   then self._avaImg.Image   = p["topbar-icon"]  end
		if p["content-icon"] and self._bodyIcon then self._bodyIcon.Image = p["content-icon"] end
		if p.resetTimer and p.resetTimer > 0 and self._divFill then
			self._divFill.Size = UDim2.new(1, 0, 1, 0)
			_ntw(self._divFill, {Size = UDim2.new(0, 0, 1, 0)}, p.resetTimer, Enum.EasingStyle.Linear)
			task.delay(p.resetTimer, function()
				if self._alive then fallClose() end
			end)
		end
	end

	function Notif:Flash(flashColor)
		if not self._alive then return end
		local s = self._card:FindFirstChildOfClass("UIStroke")
		if s then
			local orig = s.Color
			s.Color = flashColor or Color3.new(1, 1, 1)
			_ntw(s, {Color = orig}, 0.6, Enum.EasingStyle.Quad)
		end
	end

	function Notif:SetBody(text, pulse)
		if not self._alive then return end
		self._msg.Text = text or ""
		if pulse then
			_ntw(self._msg, {TextTransparency = 0.6}, 0.1)
			task.delay(0.15, function()
				if self._alive then _ntw(self._msg, {TextTransparency = 0}, 0.25) end
			end)
		end
	end

	function Notif:SetAccent(color)
		if not self._alive then return end
		if self._iconFrame then
			local s = self._iconFrame:FindFirstChildOfClass("UIStroke")
			if s then s.Color = color end
		end
		self._accLine.BackgroundColor3 = color
	end

	function Notif:Shake()
		if not self._alive then return end
		local orig = self._card.Position
		for _, ox in ipairs({8, -8, 6, -6, 3, -3, 0}) do
			_ntw(self._card, {
				Position = UDim2.new(orig.X.Scale, orig.X.Offset + ox, orig.Y.Scale, orig.Y.Offset)
			}, 0.04, Enum.EasingStyle.Quad)
			task.wait(0.045)
		end
		self._card.Position = orig
	end

	return Notif
end

return APTX
