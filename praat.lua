--**********************************************************************
--* Praat - Dialogue system for LOVE                                   *
--* Copyright (C) 2023 michyo (Michiyo Tagami)                         *
--* Licensed under the MOUSEY license                                  *
--* See LICENSE.txt for more information about the license.            *
--**********************************************************************

utf8 = require("utf8")

local praat = {}

praat.table, praat.lines = {}, {}
praat.at, praat.interval, praat.nowLine = 0, 0.1, 1
praat.nameBGarea, praat.textBGarea = nil, nil
praat.textBGcolor, praat.textLINEcolor, praat.textLINEwidth = {0, 0, 0, 0.8}, {1, 1, 1}, 2
praat.textFGarea = nil; praat.textFGcolor = {1, 1, 1}; praat.textFGfont = nil
praat.textFGlineh = 0; praat.textMaxWidth = 0; praat.textMaxLines = 0
praat.nameBGcolor, praat.nameLINEcolor, praat.nameLINEwidth = {0, 0, 0, 0.8}, {1, 1, 1}, 2
praat.nameFGlt = nil; praat.nameFGcolor = {1, 1, 1}; praat.nameFGfont = nil
praat.name = "";
praat.state = 0 -- 0:Waiting inputs 1:Showing 2:Waiting reset 3:Ended
praat.waitCursor = nil
praat.wcAt, praat.wcInterval, praat.wcWidth, praat.wcAnidir, praat.wcXY = 0, 0.05, 16, true, {784, 584}

praat.init = function(praat)
  praat.textFGfont = love.graphics.getFont()
  praat.nameFGfont = love.graphics.getFont()
  repeat
  until (praat.textFGfont and praat.nameFGfont)
end

praat.setWaitCursor = function(praat, waitCursor, wcXY)
  praat.waitCursor = waitCursor
  praat.wcXY = wcXY
end

praat.setInterval = function(praat, interval)
  praat.interval = interval
end

praat.resetState = function(praat)
  praat.state = 0
end

praat.setTextBG = function(praat, textBGarea, textBGcolor, textLINEcolor, textLINEwidth)
  if textBGarea then
    praat.textBGarea = textBGarea
  end
  if textBGcolor then
    praat.textBGcolor = textBGcolor
  end
  if textLINEcolor then
    praat.textLINEcolor = textLINEcolor
  end
  if textLINEwidth then
    praat.textLINEwidth = textLINEwidth
  end
end

praat.setTextFG = function(praat, textFGarea, textFGcolor, textFGfont, textFGlineh)
  if textFGarea then
    praat.textFGarea = textFGarea
    praat.textMaxWidth = textFGarea[3]
    if textFGlineh then
      praat.textFGlineh = textFGlineh
      praat.textMaxLines = math.floor(textFGarea[4]/textFGlineh)
      --print(praat.textMaxLines)
    end
  end
  if textFGcolor then
    praat.textFGcolor = textFGcolor
  end
  if textFGfont then
    praat.textFGfont = textFGfont
  end
end

praat.setNameBG = function(praat, nameBGarea, nameBGcolor, nameLINEcolor, nameLINEwidth)
  if nameBGarea then
    praat.nameBGarea = nameBGarea
  end
  if nameBGcolor then
    praat.nameBGcolor = nameBGcolor
  end
  if nameLINEcolor then
    praat.nameLINEcolor = nameLINEcolor
  end
  if nameLINEwidth then
    praat.nameLINEwidth = nameLINEwidth
  end
end

praat.setNameFG = function(praat, nameFGlt, nameFGcolor, nameFGfont)
  if nameFGlt then
    praat.nameFGlt = nameFGlt
  end
  if nameFGcolor then
    praat.nameFGcolor = nameFGcolor
  end
  if nameFGfont then
    praat.nameFGfont = nameFGfont
  end
end

praat.addline = function(praat, name, line, reset)
  --print("added:"..name..":"..line)
  local newline = {}
  newline.type = 0
  newline.reset = reset
  newline.chars = {}
  newline.name = name
  for pos, code in utf8.codes(line) do
    table.insert(newline.chars, utf8.char(code))
    if (utf8.char(code) == "\n") then
      --print("改行！")
    end
  end
  --for i=0,#(newline.chars) do
  --  print(newline.chars[i])
  --end
  table.insert(praat.table,newline)
  --print("tableno:"..#(praat.table))
  --print(praat.table[#(praat.table)]["chars"][1])
end

praat.setState = function(praat, state)
  if (state ~= praat.state) then
    praat.state = state
    praat.wcAt = 0
    praat.wcAnidir = true; praat.wcWidth = 16
  end
end

praat.goNextDialogue = function(praat)
  --for tmpI=1, #(praat.table) do
  --  if (praat.table[tmpI]) then
  --    if (praat.table[tmpI]["chars"]) then
  --      if (praat.table[tmpI]["chars"][1]) then
  --        print("["..tmpI.."]>"..praat.table[tmpI]["chars"][1])
  --      end
  --    end
  --  end
  --end
  if praat.table[1] then
    if (praat.table[1]["reset"] and (praat.state == 2)) then
      praat.name = nil
      praat.lines = {}
      praat.nowLine = 1
      praat.table[1] = nil
      praat:newLine(praat)
    end
  else
    --print("none")
  end
end

praat.newLine = function(praat)
  --print("tableno:"..#(praat.table))
  if (#(praat.table)>1) then
    for tmpI=2,#(praat.table) do
      praat.table[tmpI-1] = praat.table[tmpI]
    end
    table.remove(praat.table, #(praat.table))
  --end
  --if (#(praat.table)>=1) then
    --print(praat.table[1]["chars"][1])
    praat.nowLine = praat.nowLine + 1
    if (praat.nowLine > praat.textMaxLines) then
      for tmpI = praat.textMaxLines, 2, -1 do
        praat.lines[tmpI-1] = praat.lines[tmpI]
      end
      praat.lines[praat.textMaxLines] = ""
      praat.nowLine = praat.textMaxLines
    end
    if praat.table[1] then
      if ((praat.name ~= praat.table[1]["name"]) and (praat.table[1]["name"] ~= nil)) then
        praat.lines = {}
        praat.nowLine = 1
      end
    end
  else
    praat:setState(3)
  end
end

praat.update = function(praat, dt)
  praat.at = praat.at + dt
  if (praat.at >= praat.interval) then
    praat.at = praat.at - praat.interval
    if praat.table[1] then
      if praat.table[1]["chars"][1] then
        praat.state = 1
        if praat.table[1]["name"] then
          praat.name = praat.table[1]["name"]
        end
        if not praat.lines[praat.nowLine] then
          praat.lines[praat.nowLine] = ""
        end
        if (praat.table[1]["chars"][1] == "\n") then
          praat.nowLine = praat.nowLine + 1
          if (praat.nowLine > praat.textMaxLines) then
            for tmpI = praat.textMaxLines, 2, -1 do
              praat.lines[tmpI-1] = praat.lines[tmpI]
            end
            praat.lines[praat.textMaxLines] = ""
            praat.nowLine = praat.textMaxLines
          end
          if not praat.lines[praat.nowLine] then
            praat.lines[praat.nowLine] = ""
          end
        else
          if (praat.textFGfont:getWidth(praat.lines[praat.nowLine] .. praat.table[1]["chars"][1]) > praat.textMaxWidth) then
            --print(praat.textMaxWidth)
            praat.nowLine = praat.nowLine + 1
            if (praat.nowLine > praat.textMaxLines) then
              for tmpI = praat.textMaxLines, 2, -1 do
                praat.lines[tmpI-1] = praat.lines[tmpI]
              end
              praat.lines[praat.textMaxLines] = ""
              praat.nowLine = praat.textMaxLines
            end
            if not praat.lines[praat.nowLine] then
              praat.lines[praat.nowLine] = ""
            end
          end
          praat.lines[praat.nowLine] = praat.lines[praat.nowLine] .. praat.table[1]["chars"][1]
        end
        table.remove(praat.table[1]["chars"], 1)
        --print(praat.lines[praat.nowLine])
      else
        --print("newline")
        if not praat.table[1]["reset"] then
          praat:newLine()
        else
          praat:setState(2);
        end
      end
    end
  end
  --love.graphics.setFont(tmpFont)
  if (praat.state == 2) then
    praat.wcAt = praat.wcAt + dt
    if (praat.wcAt > praat.wcInterval) then
      praat.wcAt = praat.wcAt - praat.wcInterval
      if praat.wcAnidir then
        praat.wcWidth = praat.wcWidth - 1
        if (praat.wcWidth < 0) then
          praat.wcWidth = 0
          praat.wcAnidir = false
        end
      else
        praat.wcWidth = praat.wcWidth + 1
        if (praat.wcWidth > 16) then
          praat.wcWidth = 16
          praat.wcAnidir = true
        end
      end
    end
  end
end

praat.draw = function(praat)
  local tmpColor = {love.graphics.getColor()}
  local tmpLineWidth = love.graphics.getLineWidth()
  local tmpFont = love.graphics.getFont()
  if praat.nameBGarea and praat.name and praat.name~="" then
    love.graphics.setColor(praat.nameBGcolor)
    love.graphics.polygon("fill", praat.nameBGarea)
    love.graphics.setColor(praat.nameLINEcolor)
    love.graphics.setLineWidth(praat.nameLINEwidth)
    love.graphics.polygon("line", praat.nameBGarea)
  end
  if praat.textBGarea then
    love.graphics.setColor(praat.textBGcolor)
    love.graphics.polygon("fill", praat.textBGarea)
    love.graphics.setColor(praat.textLINEcolor)
    love.graphics.setLineWidth(praat.textLINEwidth)
    love.graphics.polygon("line", praat.textBGarea)
  end
  love.graphics.setFont(praat.nameFGfont)
  love.graphics.setColor(praat.nameFGcolor)
  if praat.name then
    love.graphics.print(praat.name, praat.nameFGlt[1], praat.nameFGlt[2])
  end
  love.graphics.setFont(praat.textFGfont)
  love.graphics.setColor(praat.textFGcolor)
  for tmpI = 1,praat.textMaxLines do
    if praat.lines[tmpI] then
      love.graphics.print(praat.lines[tmpI], praat.textFGarea[1], praat.textFGarea[2] + praat.textFGlineh * (tmpI-1))
    end
  end
  if (praat.state == 2) then
    --print("cursor:"..praat.wcWidth)
    love.graphics.draw(praat.waitCursor, praat.wcXY[1] + (16 - praat.wcWidth)/2, praat.wcXY[2], 0, praat.wcWidth/16, 1)
  end
  --戻し
  love.graphics.setColor(tmpColor)
  love.graphics.setLineWidth(tmpLineWidth)
  love.graphics.setFont(tmpFont)
end

return praat
