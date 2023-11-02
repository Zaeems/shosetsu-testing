-- {"id":9969,"ver":"1.0.0","libVer":"1.0.0","author":"bubloo"}

local id = 9969
local baseURL = "https://ranobes.top/"
local name = "Ranobes"
local imageURL = "https://ranobes.top/templates/Dark/images/favicon.ico"
local hasCloudFlare = true
local hasSearch = true
local isSearchIncrementing = true
local searchFilters = {
}
local settings = {
}
local settingsModel = {
}
local chapterType = ChapterType.HTML
local startIndex = 1

--- Listings that users can navigate in Shosetsu.
local listings = {
    Listing("Novels", true, function(data)
        local page = data[PAGE]
        local url = baseURL .. "novels/page/" .. page
        local document = GETDocument(url)
        return {}
    end)
}

--- Shrink the website url down. This is for space saving purposes.
--- @param url string Full URL to shrink.
--- @param type int Either KEY_CHAPTER_URL or KEY_NOVEL_URL.
--- @return string Shrunk URL.
local function shrinkURL(url, type)
    if type == KEY_NOVEL_URL then
        url = url:match("/novels/([0-9]+)-([a-z-]+)")
    else
        url = url:gsub("^.-ranobes%.top/?", "")
    end
    return url
end

local function expandURL(url, type)
    url = (url:sub(1, 1) == "/" and "" or "/") .. url
    if type == KEY_NOVEL_URL then
        url = "/novels" .. url
    end
    return baseURL .. url
end

--- Get a chapter passage based on its chapterURL.
---
--- Required.
---
--- @param chapterURL string The chapters shrunken URL.
--- @return string Strings in lua are byte arrays. If you are not outputting strings/html you can return a binary stream.
local function getPassage(chapterURL)
    local chap = GETDocument(expandURL(chapterURL)):selectFirst("#arrticle")
    local title = chap:selectFirst(".title"):text()

    -- insert title at start of chapter
    chap:prepend("<h1>" .. title .. "</h1>")

    -- remove empty paragraphs & forced paragraph indents
    local toRemove = {}
    chap:traverse(NodeVisitor(function(v)
        if v:tagName() == "p" or v:tagName() == "span" then
            local nr = 0
            local tnodes = v:textNodes()

            -- remove whitespace at the start of the paragraph
            for i=0,tnodes:size()-1 do
                local tn = tnodes:get(i)
                local o = tn:text()
                local s = o:gsub("^[ \n ]+", "")

                if o ~= s then
                    tn:text(s)
                end
                if s ~= "" then
                    break
                else
                    nr = nr + 1
                end
            end

            -- remove empty paragraphs
            if v:childNodeSize() == nr then
                toRemove[#toRemove+1] = v
            end
        end

        if v:hasAttr("border") then
            v:removeAttr("border")
        end
    end, nil, true))

    for _,v in pairs(toRemove) do
        v:remove()
    end

    return pageOfElem(chap, false, css)
end

--- Load info on a novel.
--- @param novelURL string shrunken novel url.
--- @return NovelInfo
local function parseNovel(novelURL)
    local url = shrinkURL(novelURL, KEY_NOVEL_URL)

    --- Novel page, extract info from it.
    local document = GETDocument(url)
    info = document:selectFirst(".moreless__full");
    return NovelInfo()
end

--- Called to search for novels off a website.
---
--- Optional, But required if [hasSearch] is true.
---
--- @param data table @of applied filter values [QUERY] is the search query, may be empty.
--- @return Novel[] | Array
local function search(data)
    --- Not required if search is not incrementing.
    --- @type int
    local page = data[PAGE]

    --- Get the user text query to pass through.
    --- @type string
    local query = data[QUERY]

    return parseTop(GETDocument(baseURL .. "search/" .. query .. "/page/" .. page))
end

local function parseTop(doc)
    return map(doc:select("h2.title"), function(v)
        local e = v:selectFirst("a")
        return Novel {
            title = text(e),
            link = shrinkURL(e:attr("href")),
            imageURL = "https://picsum.photos/200/300" -- v:selectFirst("figure")
        }
    end)
end

-- Return all properties in a lua table.
return {
    -- Required
    id = id,
    name = name,
    baseURL = baseURL,
    listings = listings, -- Must have at least one listing
    getPassage = getPassage,
    parseNovel = parseNovel,
    shrinkURL = shrinkURL,
    expandURL = expandURL,

    -- Optional values to change
    imageURL = imageURL,
    hasCloudFlare = hasCloudFlare,
    hasSearch = hasSearch,
    isSearchIncrementing = isSearchIncrementing,
    searchFilters = searchFilters,
    settings = settingsModel,
    chapterType = chapterType,
    startIndex = startIndex,

    -- Required if [hasSearch] is true.
    search = search,
}
