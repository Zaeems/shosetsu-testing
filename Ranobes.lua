-- {"id":9969,"ver":"1.0.0","libVer":"1.0.0","author":"bubloo"}

local baseURL = "https://ranobes.top/"


local function shrinkURL(url, type)
    --if type == KEY_NOVEL_URL then
    --    url = url:match("/novels/([0-9]+)-([a-z-]+)")
    --else
    --    url = url:gsub("^.-ranobes%.top/?", "")
    --end
    return url:gsub(".-ranobes.top","")
end

local function expandURL(url, type)
    url = (url:sub(1, 1) == "/" and "" or "/") .. url
    if type == KEY_NOVEL_URL then
        url = "/novels" .. url
    end
    return baseURL .. url
end

local function parseTop(doc)
    return map(doc:select("h2.title"), function(v)
        local e = v:selectFirst("a")
        return Novel {
            title = text(e),
            link = shrinkURL(e:attr("href")),
            imageURL = doc:selectFirst("figure.cover"):attr("background-image") -- v:selectFirst("figure")
        }
    end)
end

-- Return all properties in a lua table.
return {
    -- Required
    id = 9969,
    name = "Ranobes",
    baseURL = baseURL,
    imageURL = "https://ranobes.top/templates/Dark/images/favicon.ico",
    chapterType = ChapterType.HTML,

    shrinkURL = shrinkURL,
    expandURL = expandURL,

    hasCloudFlare = true,
    hasSearch = true,
    isSearchIncrementing = true,
    startIndex = 1,

    listings = {
        Listing("Novels", true, function(data)
            return parseTop(GETDocument(expandURL("/novels/page/" .. data[PAGE])))
        end)
    },

    getPassage = function(chapterURL)
        local htmlElement = GETDocument(expandURL(chapterURL)):selectFirst(".block.story.shortstory")
        local title = htmlElement:selectFirst(".title"):text()
        htmlElement = htmlElement:selectFirst("div#arrticle")

        htmlElement:child(0):before("<h1>" .. title .. "</h1>");

        return pageOfElem(htmlElement)
    end,

    parseNovel = function(novelURL, loadChapters)
        local doc = GETDocument(expandURL(novelURL))

        local info = NovelInfo {
            title = doc:selectFirst("h1.title"):text(),
            imageURL = doc:selectFirst("div.poster > a > img"):attr("src"),
            description = doc:selectFirst(".moreless__full"),
            status = ({
                Active = NovelStatus.PUBLISHING,
                Completed = NovelStatus.COMPLETED,
            })[
            doc:selectFirst('li[title="English translation status"] > span > a'):text()
            ],
            genres = map(doc:selectFirst("div#mc-fs-genre"):select("a"):text()),
            language = doc:selectFirst('span[itemprop="locationCreated"]'):text(),
            authors = doc:selectFirst('span[itemprop="creator"]'):text(),
        }

        if loadChapters then
            info:setChapters(
                AsList(map(doc:selectFirst("ul.chapters-scroll-list"):children(), function(v)
                    local a = v:selectFirst("a")
                    return NovelChapter() {
                        title = a:text(),
                        link = a:attr("href"),
                    }
                end))
            )
        end

        return info
    end,

    search = function(data)
        local page = data[PAGE]
        local query = data[QUERY]
        return parseTop(GETDocument(baseURL .. "search/" .. query .. "/page/" .. page))
    end,
}
