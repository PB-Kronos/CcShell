--CCbrowser 1.0.0 by SamH


local tArgs = {...}
lines = {}
centered = false
page = {}
pcolor = {}
links = {"None"}
local pTerm = term.current()
local mx,my = term.getSize()
local win = window.create(pTerm,1,1,mx,my)
local webViewer = window.create(win,1,2,mx-1,my)
title = "404"

function updateTop(title, pterm)
	pterm.setCursorPos(1,1)

	pterm.setBackgroundColor(colors.gray)
	pterm.setTextColor(colors.white)
	pterm.clear()

	if title then
		print("Page : "..title)
	else
		print("Page : "..gpage)
	end
end

function reload(file)
	--gpage = "http://theoldnet.com/"
	--gpage = "http://google.com/"
	--gpage = "http://microsoft.com/"
	--gpage = "http://apple.com/"
	gpage = "http://81.110.170.100/cc/"	
	--gpage = "http://81.110.170.100/"	

	-- Determines if the file exists, and can be edited on this computer
	page = {}
	lines = {}
	if tArgs == nil then 
		sPath = nil
	else 
		sPath = tArgs[1] 
	end

	if (gpage == nil and sPath == nil) then
		webViewer.clear()
		webViewer.write("No file, or website to display")
	elseif tArgs == nil or #tArgs == 0 then
		sPath = nil
		if file == nil or file == "" then
			tArgs = nil
			url = http.get(gpage, headers)
		else
			url = http.get(file, headers)
		end
	elseif #tArgs >= 1 then
		tArgs = nil
		sPath = shell.resolve(tArgs[1])
	end

	if sPath then
		local bReadOnly = fs.isReadOnly(sPath)
		if fs.exists(sPath) and fs.isDir(sPath) then
			print("Cannot edit a directory.")
			return
		end
		h = fs.open(sPath, "r")
	end
	--title = ""

	if h or url then
		if sPath then 
			for line in h.readLine do
				lines[ #lines + 1 ] = line
			end

			h.close() 
		end
		if not sPath then
			for line in url.readLine do
				lines[ #lines + 1 ] = line
			end		
		end
		for i=1,#lines do
			p = string.find(lines[i], "<p>")
			P = string.find(lines[i], "<P>")

			a = string.find(lines[i], '<a href="')

			FinputT = string.find(lines[i], '<input type="text"')
			FinputS = string.find(lines[i], '<input type="submit"')
			Flable = string.find(lines[i], '<label')

			hed = string.find(lines[i], "<h1>")
			hrr = string.find(lines[i], "<hr>")
			t = string.find(lines[i], "<title>")
			f = string.find(lines[i], "<font")
			lis = string.find(lines[i], "<li")

			if t then
				ti = string.gsub(lines[i], "<title>", "")
				--tit = string.gsub(ti, "le>", "")
				title = string.sub(ti, 2, -9)
			elseif f then
				fo = string.gsub(lines[i], "<", "")
				fon = string.gsub(fo, ">", "")
				font = string.sub(fon, 7, -6)
				color = string.match(font, 'color="(.+)"')
				sizeq = string.match(font, 'size="(.)"')
				size = string.match(font, 'size=(.)')
				if sizeq or size then
					if color then
						cf = string.gsub(font, 'color="'..color..'"', "")
					else
						cf = font
					end

					if sizeq then
						df = string.gsub(cf, 'size="'..sizeq..'"', "")
					end

					if not sizeq then
						df = string.gsub(cf, 'size='..size..'', "")
					end
					
					if color then
						page[#page + 1] = " <Cf>:"..color..":</Cf>".. df	
					else
						page[#page + 1] = df
					end				
				elseif color then
					if not size then
						page[#page + 1] = " <Cf>:"..color..":</Cf> ".. string.gsub(font, 'color="'..color..'"', "")
					end
				else
					if not size then
						page[#page + 1] = font
					end
				end
			elseif FinputT then
				inpu = string.gsub(lines[i], "<", "")
				input = string.gsub(inpu, ">", "")
				inputT = string.sub(input, 1, -7)
				inputTval = string.match(lines[i], 'value="(.+)"')
				if inputTval then
					page[#page + 1] = "<I>:text:</I> v:"..inputTval
				else
					page[#page + 1] = "<I>:text:</I> v: "
				end
			elseif FinputS then
				Sinpu = string.gsub(lines[i], "<", "")
				Sinput = string.gsub(Sinpu, ">", "")
				SinputT = string.sub(Sinput, 1, -7)
				SinputSval = string.match(lines[i], 'value="(.+)"')
				page[#page + 1] = "<I>:submit:</I> v:"..SinputSval
			elseif Flable then
				Flab = string.gsub(lines[i], "<", "")
				Flabl = string.gsub(Flab, ">", "")
				Flabley = string.sub(Flabl, 9, -9)
				lfor = string.match(lines[i], 'for="(.+)"')
				if lfor then
					page[#page + 1] = string.gsub(Flabley, 'for="'..lfor..'"', "")
				else
					page[#page + 1] = Flabley	
				end
			elseif a then
				link = string.match(lines[i], '<a href="(.+)">')
				links[i] = link
				dlink = string.match(lines[i], '<a href="'..link..'">(.+)</a>')
				if dlink then
					page[#page + 1] = " » "..dlink.." «"
				else
					page[#page + 1] = " » "..link.." «"
				end

			elseif p then
				prt = string.gsub(lines[i], "<", "")
				err = string.gsub(prt, "p>", "")
				ern = string.sub(err, 2, -2)
				page[#page + 1] = ern
			elseif P then
				prt = string.gsub(lines[i], "<", "")
				err = string.gsub(prt, "P>", "")
				ern = string.sub(err, 2, -2)
				page[#page + 1] = ern
			elseif hed then
				he = string.gsub(lines[i], "<", "")
				hea = string.gsub(he, "<", "")
				head = string.sub(hea, 6, -5)
				page[#page + 1] = head
			elseif hrr then
				hr = string.gsub(lines[i], "<", "")
				hro = string.gsub(hr, "<", "")
				hrozon = string.sub(hro, 6, -5)
				page[#page + 1] = "hr"
			elseif lis then
				li = string.gsub(lines[i], "<", "")
				lis = string.gsub(li, "<", "")
				list = string.sub(lis, 7, -5)
				page[#page + 1] = " * "..list
			end
		end
	else
		term.redirect(webViewer)

		term.setBackgroundColor(colors.white)
		term.setTextColor(colors.red)
		term.clear()
		error("404: not found")

		sleep(0.5)
		local evt, arg1, arg2 = os.pullEvent()
		term.redirect(pTerm)

		webViewer.setBackgroundColor(colors.black)
		webViewer.setTextColor(colors.white)
		webViewer.clear()

		term.setBackgroundColor(colors.black)
		term.setTextColor(colors.white)
		term.clear()
		term.setCursorPos(1,1)
		shell.run("clear")
		return
	end
end

function drawPage(viewer, pterm, currY)

	mx,my = term.getSize()
	updateTop(title, pterm)

	term.redirect(viewer)

	term.setBackgroundColor(colors.white)
	term.clear()
	nextColor = "black"

	for k, v in pairs(page) do
		c =  string.match(v, '<Cf>:(.+):</Cf>')
		if v == "hr" then
			term.setBackgroundColor(colors.white)
			term.setTextColor(colors.black)
			term.setCursorPos(1,currY)
			for i=1,mx do
				term.write("-")
			end
		elseif string.find(v, "<I>:text:</I>")then
			term.setBackgroundColor(colors.gray)
			term.setTextColor(colors.white)
			term.setCursorPos(1,currY)
			for i=2,mx/2 do
				term.setCursorPos(i,currY)
				term.write(" ")
			end
			term.setCursorPos(2,currY)
			term.write(string.gsub(v, '<I>:text:</I> v:', " "))
			term.setTextColor(colors.black)
		elseif string.find(v, "<I>:submit:</I>")then
			currY = currY + 1
			term.setBackgroundColor(colors.gray)
			term.setTextColor(colors.white)
			term.setCursorPos(1,currY)
			l = string.match(v, 'v:(.+)')
			for i=2,#l do
				term.setCursorPos(i,currY)
				term.write(" ")
			end
			term.setCursorPos(2,currY)
			term.write(string.gsub(v, '<I>:submit:</I> v:', ""))
			term.setTextColor(colors.black)
		else
			if c then
				if colors[c] then
					term.setCursorPos(1,currY)
					term.setTextColor(colors[c])
					term.write(string.gsub(v, " <Cf>:"..c..":</Cf> ", ""))
				else
					term.setCursorPos(1,currY)
					term.setTextColor(colors.black)
					term.write(v)
				end
			else
				term.setCursorPos(1,currY)
				term.setBackgroundColor(colors.white)
				term.setTextColor(colors.black)
				term.write(v)
			end
		end
		currY = currY + 1
	end
	term.redirect(pterm)
end

function main()
	term.clear()
	print("We also have progr amarguments so you can load a html file!")
	print("Enter URL , or leave blank for demo site (How to use guide)")
	url = read()

	term.redirect(win)
	reload(url)
	local currY = 1						
	gview = "page"

	while h or url do
		if gview == "page" then
			updateTop(title, win)
			drawPage(webViewer, pTerm, currY)
			local evt, arg1, arg2 = os.pullEvent()

			if evt=="mouse_scroll" then
				if arg1==1 then
					if currY+1 == my-#page then
						currY = my-#page
					else
						currY=math.min(currY-1,my)
					end
				elseif arg1==-1 then
					if currY == 1 then
						currY = 1
					else
						currY=math.max(currY+1,0-my)
					end
				end

			elseif evt=="key" then			
				if arg1==keys.down then
					if currY+1 == my-#page then
						currY = my-#page
					else
						currY=math.min(currY-1,my)
					end
				elseif arg1==keys.up then
					if currY == 1 then
						currY = 1
					else
						currY=math.max(currY+1,0-my)
					end
				elseif arg1==keys.r then
					reload()
					updateTop(title, win)
					drawPage(webViewer, win, currY)
				elseif arg1==keys.leftCtrl then
					gview = "off"
				elseif arg1== keys.a then
					gveiw = "off"					
				end
			end
		elseif gview == "off" then
			return
			--gview = "page"
		end
	end
end

help.setPath( help.path() .. ":/web/help/html.txt" )

headers = {
  [ "User-Agent" ] = "CCbrowser/1.0.0(CraftOS)CCwebKit/1.0.0(KHTML, like Gecko) Version/13.1 CCbrowser/1.0.0", -- Overrides the default User-Agent.
}

no_error, message = pcall(main)
term.redirect(pTerm)
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1,1)
if not no_error then
	print(message)
else
	print("Goodbye!")
end

		-- elseif arg1==keys.pageDown then
		-- 	currY=math.max(currY+my-1,my-1)
		-- 	drawPage(webViewer, pTerm, currY)
		-- elseif arg1==keys.pageUp then
		-- 	currY=math.min(currY-my-1,1)
		-- 	drawPage(webViewer, pTerm, currY)
		-- elseif arg1==keys.home then
		-- 	currY=1
		-- 	drawPage(webViewer, pTerm, currY)
		-- elseif arg1==keys["end"] then
		-- 	currY=my+1
		-- 	drawPage(webViewer, pTerm, currY)