--CharlesMine Mobile; port to Lua

--global definitions
BLOCK_XMAX,BLOCK_YMAX = 100,100
BLOCKSIZE_X,BLOCKSIZE_Y = 24,20
BLOCKDELTA_X,BLOCKDELTA_Y = 13,20
BLOCK_AREA_X,BLOCK_AREA_Y = 12,60
BLOCK_AREA_EDGE_X,BLOCK_AREA_EDGE_Y = 12,12
--frame
FRAME_INNER_OFFSET_X,FRAME_INNER_OFFSET_Y = 2,3
--new game button
BUTTONWIDTH,BUTTONHEIGHT = 24,24
BUTTONEDGE_TOP  = 15
--splash logo
LOGOWIDTH,LOGOHEIGHT=240,200
--timers
DIGITWIDTH,DIGITHEIGHT,DIGITCOUNT = 13,23,3
DIGITEDGE_LEFT,DIGITEDGE_RIGHT,DIGITEDGE_TOP,DIGITEDGE_BOTTOM  = 15,15,15,15
--text
TEXTHEIGHT = 12
--game modes
MODE_EASY_MAPX,MODE_EASY_MAPY,MODE_EASY_MINE = 15,14,12
MODE_NORMAL_MAPX,MODE_NORMAL_MAPY,MODE_NORMAL_MINE = 21,15,50
MODE_HARD_MAPX,MODE_HARD_MAPY,MODE_HARD_MINE = 41,15,99
MAPX_MIN,MAPX_MAX,MAPY_MIN,MAPY_MAX = MODE_EASY_MAPX,MODE_HARD_MAPX,MODE_EASY_MAPY,MODE_HARD_MAPY
MINE_MIN = MODE_EASY_MINE

function MINE_MAX(x,y)
   return ((x-1)*(y-1))
end
--misc items
ADVANCED_TIME_MAX = 2147483646
TRANSPARENT_COLOR = color.new(255,0,255)

-- forward function declarations
local Window_Paint
local UpdateBlockNumbers
local LoadDefaultMap
local InitMap
local LButton_Down
local LButton_Up
local RButton_Down
local RButton_Up
local BlockAbutting

-- forward variables declarations
local nWndCX, nWndCY

-- splash window
function Splash()
	local nScreenX = screen.width()
	local nScreenY = screen.height()
	local bmpLogo = image.load("res\\LOGO.png")
	screen.fillrect(0,0, nScreenX, nScreenY, color.new(255,255,255))
	bmpLogo:draw(nScreenX/2-LOGOWIDTH/2, nScreenY/2-LOGOHEIGHT/2)
	bmpLogo:close()
	bmpLogo = nil
	
	screen.update()
	os.sleep(200)
end

function InitGame()
	math.randomseed(os.time())
	
	hGame_BlockBitmap = image.load("res\\Blocks.png")
	hGame_ButtonBitmap = image.load("res\\Button.png")
	hGame_DigitBitmap = image.load("res\\Digit.png")
	hGame_MarkerBitmap = image.load("res\\Marker.png")
	ptPressItemX, ptPressItemY = -1,-1
	nStateMax=2
	bBothClicked=false
	
	g_bMarking=false
	g_bContinuousMarking=false

	
	LoadDefaultMap(0)
end

function DestroyGame()
	if hGame_BlockBitmap ~= nil then
		hGame_BlockBitmap:close()
		hGame_BlockBitmap=nil
	end
	if hGame_ButtonBitmap ~= nil then
		hGame_ButtonBitmap:close()
		hGame_ButtonBitmap=nil
	end
	if hGame_DigitBitmap ~= nil then
		hGame_DigitBitmap:close()
		hGame_DigitBitmap=nil
	end
	if hGame_MarkerBitmap ~= nil then
		hGame_MarkerBitmap:close()
		hGame_MarkerBitmap=nil
	end
end

function LoadDefaultMap(nMode)
	if nMode==0 then
		nMapX = MODE_EASY_MAPX
		nMapY = MODE_EASY_MAPY
		nMine = MODE_EASY_MINE
		nGameMode = 0
	elseif nMode==1 then
		nMapX = MODE_NORMAL_MAPX
		nMapY = MODE_NORMAL_MAPY
		nMine = MODE_NORMAL_MINE
		nGameMode = 1
	elseif nMode==2 then
		nMapX = MODE_HARD_MAPX
		nMapY = MODE_HARD_MAPY
		nMine = MODE_HARD_MINE
		nGameMode = 2
	else
		nGameMode = 3
	end
	
	InitMap()
end

function GetItemImage(X, Y)
	if not ValidateBlock(X,Y) then
		return 0
	end

	if bBothClicked and not BlocksArray[Y][X]["bBlockOpen"] and BlocksArray[Y][X]["nBlockState"] ~= 1 and BlockAbutting(ptPressItemX, ptPressItemY, X, Y) then
		if BlocksArray[Y][X]["nBlockState"]==2 then
			return 6
		end
		return 19;
	end

	if not BlocksArray[Y][X]["bBlockOpen"] then      --Not Open
		if nGameState>=2 then       --Game Is Over
			if BlocksArray[Y][X]["bMineExist"] then
				if BlocksArray[Y][X]["nBlockState"] ~= 1 then
					return 5
				else
					return 1
				end
			else
				if BlocksArray[Y][X]["nBlockState"] == 1 then
					return 4
				end
			end
		elseif (BlocksArray[Y][X]["nBlockState"]~=1) and X==ptPressItemX and Y==ptPressItemY then
			if BlocksArray[Y][X]["nBlockState"]==2 then
				return 6
			end
			return 19
		end
		return BlocksArray[Y][X]["nBlockState"]
	end

	if BlocksArray[Y][X].bMineExist then      --Open But Mine;
		return 3
	else
		return 19-BlocksArray[Y][X]["nBlockNumber"]
	end
	return 0
end

function BeginGame()
	nTimeCount = 0
	nGameState = 1
	nStartTime = os.time()
end

function EndGame(nEndType)
	nGameState = 2+nEndType
	ptPressItemX,ptPressItemY = -1,-1;
	Window_Paint()
end

function OpenBlock(X, Y)
	if not ValidateBlock(X,Y) then
		return
	end
	if BlocksArray[Y][X]["bBlockOpen"] or BlocksArray[Y][X]["nBlockState"]==1 then
		return
	end
	BlocksArray[Y][X]["bBlockOpen"] = true
	if BlocksArray[Y][X]["bMineExist"] then
		EndGame(0)
	end
	nBlockLeftCount=nBlockLeftCount-1
	
	if not BlocksArray[Y][X]["bMineExist"] and BlocksArray[Y][X]["nBlockNumber"]==0 then
		BlastBlock(X, Y);
	end

	if nBlockLeftCount<=nMine and nGameState==1 then
		for i=0,nMapY-1 do
			for j=0,nMapX-1 do
				if not BlocksArray[i][j]["bBlockOpen"] and BlocksArray[i][j]["nBlockState"] ~= 1 then
					BlocksArray[i][j]["nBlockState"] = 1
					nMineLeftCount = nMineLeftCount - 1
				end
			end
		end
		
		EndGame(1)
	end
end

function BlastBlock(X, Y)
	ptPressItemX,ptPressItemY = -1,-1

	if not ValidateBlock(X,Y) then
		return
	end
	
	if not BlocksArray[Y][X]["bBlockOpen"] then
		return
	end

	local tmarkcount = 0;
	for i=Y-1,Y+1 do
		for j=X-2,X+2 do
			if BlockAbutting(X, Y, j, i) then
				if BlocksArray[i][j]["nBlockState"]==1 then
					tmarkcount=tmarkcount+1
				end
			end
		end
	end
	if tmarkcount==BlocksArray[Y][X]["nBlockNumber"] or BlocksArray[Y][X]["nBlockNumber"]==0 then
		OpenBlock(X-1,Y-1)
		OpenBlock(X,  Y-1)
		OpenBlock(X+1,Y-1)
		OpenBlock(X-2,Y  )
		OpenBlock(X-1,Y  )
		OpenBlock(X,  Y  )
		OpenBlock(X+1,Y  )
		OpenBlock(X+2,Y  )
		OpenBlock(X-1,Y+1)
		OpenBlock(X,  Y+1)
		OpenBlock(X+1,Y+1)
		
		if BlockDirection(X,Y)==0 then
			OpenBlock(X-2, Y-1)
			OpenBlock(X+2, Y-1)
		else
			OpenBlock(X-2, Y+1)
			OpenBlock(X+2, Y+1)
		end
	end

end

function BlockAbutting(pt1X, pt1Y, pt2X, pt2Y)
	if not ValidateBlock(pt1X,pt1Y) or not ValidateBlock(pt2X,pt2Y) then
		return false
	end
	if pt2X>=pt1X-1 and pt2X<=pt1X+1 and pt2Y>=pt1Y-1 and pt2Y<=pt1Y+1 then
		return true
	end
	if BlockDirection(pt1X,pt1Y)==0 then
		if pt2Y == pt1Y - 1 or pt2Y == pt1Y then
			if pt2X==pt1X-2 or pt2X==pt1X+2 then
				return true
			end
		end	
	else
		if pt2Y == pt1Y + 1 or pt2Y == pt1Y then
			if pt2X==pt1X-2 or pt2X==pt1X+2 then
				return true
			end
		end
	end
	return false
end

function BlockFromPt(ptX, ptY)
	ptX = ptX - nClientOffsetX
	if (ptX>=nButtonX and ptX<(nButtonX+BUTTONWIDTH)) and (ptY>=nButtonY and ptY<(nButtonY+BUTTONHEIGHT)) then
		return -2,-2
	end

	if (ptX>=nMarkerButtonX and ptX<(nMarkerButtonX+BUTTONWIDTH)) and (ptY>=nMarkerButtonY and ptY<(nMarkerButtonY+BUTTONHEIGHT)) then
		return -3,-3
	end

	retValueY = math.floor((ptY-BLOCK_AREA_Y+BLOCKSIZE_Y)/BLOCKSIZE_Y)-1;

	if retValueY<0 or retValueY>=nMapY then
		return -1,-1
	end

	local xmin,xmax = math.floor((ptX-BLOCK_AREA_X-(BLOCKSIZE_X-1))/BLOCKDELTA_X),math.floor((ptX-BLOCK_AREA_X)/BLOCKDELTA_X) 
	if xmin<0 then
		xmin=0
	end
	if xmax>=nMapX then
		xmax = nMapX-1
	end

	for i = xmin, xmax do
		local tx = ptX - BLOCK_AREA_X - i * BLOCKDELTA_X
		if  tx >= 0 and tx< BLOCKSIZE_X then
			-- in lua we can't get a specified pixel from an image. so we 'll use hard-coded if-statement directly.
			local ty = ptY - BLOCK_AREA_Y - retValueY * BLOCKDELTA_Y
			if BlockDirection(i, retValueY) ==0 then                   -- tip down
				if tx < BLOCKSIZE_X/2 then  -- left side \, see if it's in upper.
					if ty <= tx * 5 / 3 then
						retValueX = i
						break
					end
				else             -- right side /, see if it's in upper.
					if ty <= (BLOCKSIZE_X - 1 - tx) * 5 / 3 then
						retValueX = i
						break
					end
				end 
			else
				if tx < BLOCKSIZE_X/2 then  -- left side /, see if it's in lower.
					if ty >= BLOCKSIZE_Y - 1 - tx * 5 / 3 then
						retValueX = i
						break
					end
				else             -- right side \, see if it's in lower.
					if ty >= BLOCKSIZE_Y - 1 - (BLOCKSIZE_X - 1 - tx) * 5 / 3 then
						retValueX = i
						break
					end
				end
			end
			retValueX = i
		end		
	end

	return retValueX,retValueY
end

function IsMine(X, Y)
	if not ValidateBlock(X,Y) then
		return false
	end
	return BlocksArray[Y][X]["bMineExist"]
end

function BlockDirection(X, Y)
	return (X+Y)%2
end

function ValidateBlock(X, Y)
	if X<0 or X>=nMapX or Y<0 or Y>=nMapY then
		return false
	end
	return true;
end

function RecalcRect()

	local nScreenX = screen.width()
	local nScreenY = screen.height()
	
	nWndCX = BLOCK_AREA_X + BLOCKSIZE_X + (nMapX-1) * BLOCKDELTA_X + BLOCK_AREA_EDGE_X;
	nWndCY = BLOCK_AREA_Y + BLOCKSIZE_Y + (nMapY-1) * BLOCKDELTA_Y + BLOCK_AREA_EDGE_Y;

	nDigit1X = DIGITEDGE_LEFT;
	nDigit2X = nWndCX - DIGITEDGE_RIGHT - DIGITWIDTH*DIGITCOUNT;
	nDigit1Y = BUTTONEDGE_TOP;
	nDigit2Y = BUTTONEDGE_TOP;

	nButtonX = math.floor(
			   (nWndCX - BUTTONWIDTH)/2  );
	nButtonY = BUTTONEDGE_TOP;

	nMarkerButtonX = math.floor(
					 (nWndCX - BUTTONWIDTH)/2 );
	nMarkerButtonY = nWndCY;

	nClientOffsetX = math.floor( (nScreenX - nWndCX)/2 );
	nClientOffsetY = 0;
	nClientOffsetY = math.floor( (nScreenY - nWndCY)/2 )	;
	nWndCX = nScreenX;
	nWndCY = nScreenY;
end

-- update block nearby mine numbers
function UpdateBlockNumbers()
	for i=0,nMapY-1 do
		for j=0,nMapX-1 do
			local nMineNumber=0
			if IsMine(j-1,i-1) then nMineNumber=nMineNumber+1 end
			if IsMine(j,  i-1) then nMineNumber=nMineNumber+1 end
			if IsMine(j+1,i-1) then nMineNumber=nMineNumber+1 end
			if IsMine(j-2,i  ) then nMineNumber=nMineNumber+1 end
			if IsMine(j-1,i  ) then nMineNumber=nMineNumber+1 end
			if IsMine(j,  i  ) then nMineNumber=nMineNumber+1 end
			if IsMine(j+1,i  ) then nMineNumber=nMineNumber+1 end
			if IsMine(j+2,i  ) then nMineNumber=nMineNumber+1 end
			if IsMine(j-1,i+1) then nMineNumber=nMineNumber+1 end
			if IsMine(j,  i+1) then nMineNumber=nMineNumber+1 end
			if IsMine(j+1,i+1) then nMineNumber=nMineNumber+1 end

			if BlockDirection(j,i)==0 then
				if(IsMine(j-2,i-1)) then nMineNumber=nMineNumber+1 end
				if(IsMine(j+2,i-1)) then nMineNumber=nMineNumber+1 end
			else
				if(IsMine(j-2,i+1)) then nMineNumber=nMineNumber+1 end
				if(IsMine(j+2,i+1)) then nMineNumber=nMineNumber+1 end
			end

			BlocksArray[i][j]["nBlockNumber"] = nMineNumber
		end
	end    
end

-- draw 3d rectangle stub
function Draw3DRect(x, y, cx, cy, color1, color2)
	screen.drawline(   x,    y,    x, y+cy, color1, 2)
	screen.drawline(   x,    y, x+cx,    y, color1, 2)
	screen.drawline(x+cx, y+cy,    x, y+cy, color2, 2)
	screen.drawline(x+cx, y+cy, x+cx,    y, color2, 2)	
end

-- draw digit
function DrawDigit(digitX, digitY, nDigit)
	local p,q=10,1
	local value = math.abs(nDigit)
	for i=0, DIGITCOUNT-1 do
		if i==DIGITCOUNT-1 and nDigit<0 then   -- draw the negative symbol
			hGame_DigitBitmap:draw(digitX+(DIGITCOUNT-i-1)*DIGITWIDTH, digitY, digitX+(DIGITCOUNT-i-1)*DIGITWIDTH, digitY, DIGITWIDTH, DIGITHEIGHT)
		else
			hGame_DigitBitmap:draw(digitX+(DIGITCOUNT-i-1)*DIGITWIDTH, digitY - DIGITHEIGHT*(11-math.floor((value%p)/q)), digitX+(DIGITCOUNT-i-1)*DIGITWIDTH, digitY, DIGITWIDTH, DIGITHEIGHT)
		end
		p,q=p*10,p
	end
end

-- draw game button
function DrawButton(x, y)
	local t = -1
	if ptPressItemX==-2 and ptPressItemY==-2 then
		t = 0;
	elseif nGameState >= 2 then
		t = 4 - nGameState
	elseif ptPressItemX~=-1 and ptPressItemY~=-1 then
		t = 3
	else
		t = 4
	end
	hGame_ButtonBitmap:draw(x, y - t * BUTTONHEIGHT, x, y, BUTTONWIDTH, BUTTONHEIGHT)
end

-- draw marker button
function DrawMarkerButton(x, y)	
	local t = -1
	if g_bMarking or (ptPressItemX==-3 and ptPressItemY==-3) then
		t = 0
	else
		t = 1
	end
	hGame_MarkerBitmap:draw(x, y - t * BUTTONHEIGHT, x, y, BUTTONWIDTH, BUTTONHEIGHT)
end

-- draw text button
function DrawText1(x, y, xe)
	text.color(color.new(255,0,0))
	text.draw(x,y,"×êÊ¯É¨À×","left", xe)    --right to left...
	text.draw(x,y + TEXTHEIGHT,"Special Edition","left", xe)
end

function DrawText2(x, y, xe)
	text.color(color.new(0,0,255))
	text.draw(xe,y,"CrLF0710","right", x)    --right to left...
	text.draw(xe,y + TEXTHEIGHT,"[USTC]","right", x)
end

-- update screen.
function Window_Paint()
	local nScreenX = screen.width()
	local nScreenY = screen.height()
	
	--demo
	screen.fillrect(0,0, nScreenX, nScreenY, color.new(0,0,0))
	screen.fillrect(0,0, nWndCX,    nWndCY,    color.new(192,192,192))
	
	Draw3DRect(0, 0, nWndCX, nWndCY, color.new(255, 255, 255), color.new(128, 128, 128));

	Draw3DRect(nClientOffsetX+ BLOCK_AREA_X - FRAME_INNER_OFFSET_X, BUTTONEDGE_TOP - FRAME_INNER_OFFSET_Y, (nMapX-1) * BLOCKDELTA_X + BLOCKSIZE_X + FRAME_INNER_OFFSET_X * 2,
		BUTTONHEIGHT + FRAME_INNER_OFFSET_Y * 2, color.new(128, 128, 128), color.new(255, 255, 255));	
			
	Draw3DRect(nClientOffsetX+ BLOCK_AREA_X - FRAME_INNER_OFFSET_X, BLOCK_AREA_Y - FRAME_INNER_OFFSET_Y, (nMapX-1) * BLOCKDELTA_X + BLOCKSIZE_X + FRAME_INNER_OFFSET_X * 2,
		(nMapY-1) * BLOCKDELTA_Y + BLOCKSIZE_Y + FRAME_INNER_OFFSET_Y * 2, color.new(128, 128, 128), color.new(255, 255, 255));

	DrawDigit(nClientOffsetX+ nDigit1X, nDigit1Y, nMineLeftCount);
	DrawDigit(nClientOffsetX+ nDigit2X, nDigit2Y, nTimeCount);

	DrawButton(nClientOffsetX+ nButtonX, nButtonY);

	DrawText1 (nClientOffsetX + BLOCK_AREA_X - FRAME_INNER_OFFSET_X , nMarkerButtonY, 
		nClientOffsetX+ nMarkerButtonX)
		
	DrawText2 (nClientOffsetX + BLOCK_AREA_X - FRAME_INNER_OFFSET_X + (nMapX-1) * BLOCKDELTA_X + BLOCKSIZE_X + FRAME_INNER_OFFSET_X * 2, nMarkerButtonY, 
		nClientOffsetX+ nMarkerButtonX + BUTTONWIDTH)
	
	DrawMarkerButton(nClientOffsetX+ nMarkerButtonX, nMarkerButtonY)
	
	for i=0,nMapY-1 do
		for j=0,nMapX-1 do
			if BlockDirection(j, i)==1 then
				hGame_BlockBitmap:draw(nClientOffsetX+ BLOCK_AREA_X + BLOCKDELTA_X*j - 0          ,BLOCK_AREA_Y + BLOCKDELTA_Y*i - GetItemImage(j, i) * BLOCKSIZE_Y,
					nClientOffsetX+ BLOCK_AREA_X + BLOCKDELTA_X*j,BLOCK_AREA_Y + BLOCKDELTA_Y*i, BLOCKSIZE_X, BLOCKSIZE_Y)
			else
				hGame_BlockBitmap:draw(nClientOffsetX+ BLOCK_AREA_X + BLOCKDELTA_X*j - BLOCKSIZE_X, BLOCK_AREA_Y + BLOCKDELTA_Y*i - GetItemImage(j, i) * BLOCKSIZE_Y,
					nClientOffsetX+ BLOCK_AREA_X + BLOCKDELTA_X*j,BLOCK_AREA_Y + BLOCKDELTA_Y*i , BLOCKSIZE_X, BLOCKSIZE_Y)
			end
		end
	end


	screen.update()
	return
end

-- initialize map
function InitMap()
	nGameState = 0
	RecalcRect()
	
	g_bMarking = false
	g_bContinuousMarking = false
	
	nTimeCount = 0
	nMineLeftCount = nMine
	nBlockLeftCount = nMapX*nMapY

	BlocksArray = {}
	for i=0,nMapY-1 do
		BlocksArray[i]={}	
		for j=0,nMapX-1 do
			BlocksArray[i][j] = {}
			BlocksArray[i][j]["bMineExist"] = false 
			BlocksArray[i][j]["bBlockOpen"] = false
			BlocksArray[i][j]["nBlockNumber"] = -1
			BlocksArray[i][j]["nBlockState"] = 0
		end
	end

	for i=0,nMine-1 do
		local x, y;
		repeat
			x = math.random(0, nMapX-1);
			y = math.random(0, nMapY-1);
		until BlocksArray[y][x]["bMineExist"] == false
		BlocksArray[y][x].bMineExist = true;
	end

	UpdateBlockNumbers();
	Window_Paint();
end

-- lbutton_down
function LButton_Down()
	local xPos, yPos = touch.pos()	 
	local ptNewX, ptNewY = BlockFromPt(xPos, yPos)

	if (ptNewX==-2 and ptNewY==-2) or (ptNewX==-3 and ptNewY==-3) then
		ptPressItemX, ptPressItemY = ptNewX,ptNewY
		Window_Paint()

		return
	elseif ptNewX>=0 and ptNewY>=0 then
		if g_bMarking then

			RButton_Down()
			RButton_Up()

			return
		end

		if nGameState>=2 then
			return
		end
		if ptPressItemX ~= ptNewX or ptPressItemY ~= ptNewY then
			ptPressItemX, ptPressItemY = ptNewX, ptNewY
			Window_Paint()
		end
	end
end

function LButton_Up()
	local xPos, yPos = touch.pos() 
	local ptX, ptY = BlockFromPt(xPos, yPos);


	if ptX==-2 and ptY==-2 then
		ptPressItemX, ptPressItemY = -1,-1

		InitMap()
		Window_Paint()
		return
	elseif ptX==-3 and ptY==-3 then
		ptPressItemX, ptPressItemY = -1,-1

		g_bMarking = not g_bMarking

		Window_Paint()
		return
	elseif ptX>=0 and ptY>=0 then
		ptPressItemX, ptPressItemY = -1,-1

		if g_bMarking then
			if not g_bContinuousMarking then
				g_bMarking = false
				Window_Paint()
			end
			return	
		end

		if nGameState>=2 then
			return
		end
				
		if nGameState==0 then
			BeginGame()
		end
		if not BlocksArray[ptY][ptX]["bBlockOpen"] and BlocksArray[ptY][ptX]["nBlockState"]~=1 then
			OpenBlock(ptX, ptY)
		end

		Window_Paint()
	end

end


function RButton_Down()
	local xPos, yPos = touch.pos() 
	local ptX, ptY = BlockFromPt(xPos, yPos);

	if ptX>=0 and ptY>=0 then
		if nGameState>=2 then
			return
		end

		if not BlocksArray[ptY][ptX]["bBlockOpen"] then
			if BlocksArray[ptY][ptX]["nBlockState"]==1 then
				nMineLeftCount=nMineLeftCount+1;
			end

			BlocksArray[ptY][ptX]["nBlockState"] = BlocksArray[ptY][ptX]["nBlockState"]+1;

			if BlocksArray[ptY][ptX]["nBlockState"] > nStateMax then
				BlocksArray[ptY][ptX]["nBlockState"] = 0
			end

			if BlocksArray[ptY][ptX]["nBlockState"] == 1 then
				nMineLeftCount=nMineLeftCount-1
			end

			Window_Paint()
		end
	end
end

function RButton_Up()
	-- no action needed.
end

-- update time
function Update_Time()
	if nGameState ~= 1 then
		return
	end
	if nTimeCount ~= os.time() - nStartTime then
		nTimeCount = os.time() - nStartTime
		Window_Paint()
	end
end


-- main
nOldOrientation = screen.orientation()
nOldTextColor   = text.color(color.new(0,0,255))
nOldTextSize    = text.size(12)
screen.orientation(1)
Splash()
InitGame()
Window_Paint()
while 1 do
	if control.read()==1 then
		if control.isButton()==1 then
			if button.click()==1 then
				break
			end
		elseif control.isTouch()==1 then
			if touch.down()==1 then
				LButton_Down()
			end
			if touch.up()==1 or touch.click()==1 then
				LButton_Up()
			end
		end
	else
		Update_Time()
		os.sleep(10)
	end
end
DestroyGame()
text.color(nOldTextColor)
screen.orientation(nOldOrientation)
