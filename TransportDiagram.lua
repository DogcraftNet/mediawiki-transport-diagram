-- Copyright (c) 2022, William278, Dogcraft.net and contributors
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
-- to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
-- WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-- 
-- End license text.

-- A Module for generating mini diagrams of transport networks
local p = {}
local data = ""
local title = "Transport Diagram"
local totalTracks = 1

-- Extract the first internal link from a string and return its target page
local function findLink(text)
	text = string.match(text, "%[%[.-%]%]")
	if text == nil then 
		return "" 
	end
	text = string.gsub(text, "[%[%]]", "")
	text = mw.text.split(text, "|", true)[1]
	return text	
end

-- Generate the HTML for a diagram row
local function generateRow(tracks, trackTypes, leftStation, rightStation)
    -- Create the row HTML
    local lineHtml = "<div class='diagram-row'>"
    
    -- Get a station link if present
    local stationLink = findLink("" .. leftStation .. rightStation)

    -- Add the left station text
    lineHtml = lineHtml .. "<div class='station station-left'>" .. leftStation .. "</div>"

    -- Add container box, with fixed width based on tracks count
    local width = 30 * totalTracks
    lineHtml = lineHtml .. "<div class='track-container' style='width: " .. tostring(width) .. "px'>"

    -- Add the track images
    for trackIndex = 1, totalTracks do
        if tracks[trackIndex] ~= nil then
            -- If station or interchange, set targetPage to stationLink
            local targetPage = ""
            local trackCodeStart = string.sub(tracks[trackIndex], 1, 3)
    		targetPage = (trackCodeStart == "STN" or trackCodeStart == "ITC") and stationLink or ""
            
            -- Add the track
            lineHtml = lineHtml ..
                "<div class='track'>[[File:TIcon " ..
                trackTypes[trackIndex] .. " " .. tracks[trackIndex] .. ".png|link=" .. targetPage .. "]]</div>"
        else
            -- Add a blank track if there isn't a track for this index
            lineHtml = lineHtml .. "<div class='track'>[[File:TIcon Blank.png|link=]]</div>"
        end
    end
    lineHtml = lineHtml .. "</div>"

    -- Add the right station text
    lineHtml = lineHtml .. "<div class='station station-right'>" .. rightStation .. "</div></div>"
    return lineHtml
end

-- Parses a line and generates the HTML for it
local function parseLine(line)
    -- Prepare values for row generation
    local tracks = {}
    local trackTypes = { "SRN", "SRB", "SRB", "SRB" }
    local leftStation = ""
    local rightStation = ""

    -- Trim the line of whitespace
    line = mw.text.trim(line)

    -- Split the line into colon separated key-pairs by commas
    local pairs = mw.text.split(line, ",", true)
    for i = 1, #pairs do
        -- Get the value
        local value = pairs[i]

        -- Split the key-pair into a key and a value
        local keyValue = mw.text.split(value, ":", true)
        local key = mw.text.trim(keyValue[1])
        local value = mw.text.trim(keyValue[2])

        -- Parse the key and set the appropraite value
        if (key == "diagram-title" or key == "title") then
            title = value
        elseif (key == "diagram-tracks" or key == "tracks") then
            totalTracks = tonumber(value)
        elseif (key == "station") then
            leftStation = value
        elseif (key == "station2" or key == "station-right") then
            rightStation = value
        else
            -- Handle track and trackType definitions
            if string.sub(key, 1, 5) == "track" then
                -- Get the track number
                local trackNumber = string.sub(key, 6, 6)
                if trackNumber == "-" or trackNumber == "" or trackNumber == nil then
                    trackNumber = "1"
                end

                -- If the key ends with -type, then it's a track type key
                if string.sub(key, -5) == "-type" then
                    trackTypes[tonumber(trackNumber)] = value
                else
                    tracks[tonumber(trackNumber)] = value
                end
            end
        end
    end

    -- If tracks is empty, then there's no data for this line
    if next(tracks) == nil then
        return ""
    end

    return generateRow(tracks, trackTypes, leftStation, rightStation)
end

-- Generates the html for provided diagram markup
local function generate()
    -- Trim data of whitespace
    data = mw.text.trim(data)

    -- Use mw.text.split to split the data into lines
    local lines = mw.text.split(data, "\n")

    -- Iterate through each line, calling parseLine on it and appending the string result of that to an output data
    local output = ""
    for _, line in ipairs(lines) do
        output = output .. parseLine(line)
    end
    return "<div class='transport-diagram phonefullscreen'><div class='transport-diagram-title'>" ..
        title .. "</div>" .. output .. "</div>"
end

-- The main function called on #invoke via the template
function p.transportDiagram(frame)
    local args = {}
    if frame == mw.getCurrentFrame() then
        args = frame:getParent().args
    else
        args = frame
    end

    -- Iterate through each key pair in args
    for key, value in pairs(args) do
        -- Add to data
        data = data .. value
    end

    return generate()
end

return p
