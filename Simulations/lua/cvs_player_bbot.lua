function fromCSV (s)
   s = s .. ','        -- ending comma
   local t = {}        -- table to collect fields
   local fieldstart = 1
   repeat
      -- next field is quoted? (start with `"'?)
      if string.find(s, '^"', fieldstart) then
         local a, c
         local i  = fieldstart
         repeat
            -- find closing quote
            a, i, c = string.find(s, '"("?)', i+1)
         until c ~= '"'    -- quote not followed by quote?
         if not i then error('unmatched "') end
         local f = string.sub(s, fieldstart+1, i-1)
         table.insert(t, (string.gsub(f, '""', '"')))
         fieldstart = string.find(s, ',', i) + 1
      else                -- unquoted; find next comma
         local nexti = string.find(s, ',', fieldstart)
         table.insert(t, string.sub(s, fieldstart, nexti-1))
         simAuxiliaryConsolePrint(consoleHandle, string.sub(s, fieldstart, nexti-1)..'\n')
         fieldstart = nexti + 1
      end
   until fieldstart > string.len(s)
   return t
end


function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

function parseCSVFile(u, id)
   local data={}
   local out=""
   fname=simExtCustomUI_getEditValue(ui, 1001)
   print("fname=",fname)
   if file_exists(fname) then
      print("File exists!")
   else
      out=string.format("Failed to parse!<br>Could not find file:<br>%s",fname)
      simExtCustomUI_setLabelText(ui, 1003, out)
      return nil
   end
   -- Now parse file into table:
   local i=1
   local parsedLine={}

   for line in io.lines(fname) do
      local parsedLine=fromCSV(line)
      if (#parsedLine < 9) then
         out=string.format("Error Parsing: Line %d only has %d length)<br>Raw:<br>%s",i,#parsedLine,line)
         return nil
      end
      local q={}
      for j=1,#parsedLine,1 do
         table.insert(q, tonumber(parsedLine[j]))
         if (q[j]==nil) then
            out=string.format("Failed to parse!<br>Could not convert line %d!<br> Raw Value=%s",i,line)
            simExtCustomUI_setLabelText(ui, 1003, out)
            return nil
         end
      end
      data[i]=q
      i=i+1
   end
   -- for i=1,10,1 do
   --     print(string.format("data[%d]=(%f,%f,%f,%f,%f,%f)",i,data[i][i],data[i][2],data[i][3],data[i][4],data[i][5],data[i][6]))
   -- end
   simAuxiliaryConsolePrint(consoleHandle, tostring(io.lines(fname))..'File length\n')
   simAuxiliaryConsolePrint(consoleHandle, 'Before\n')
   jointData=data

   out=string.format("Successfully parsed file!<br>Filename = %s<br>Line count = %d",fname,i)
   simExtCustomUI_setLabelText(ui, 1003, out)
   simAuxiliaryConsolePrint(consoleHandle, 'Print out/n')
end

function interpConfig(data,tinterp,dt)
   local t=0
   local q={0,0,0,0,0,0,0,0,0}
   local reset=nil
   -- get the largest index in the table where tvec[index]<=tinterp
   local keyIndex = math.floor(tinterp/dt)+1
   if (keyIndex<1) then
      print("interpConfig Error: keyIndex < 1!")
      q=data[1]
   elseif (keyIndex==#data) then
      print("interpConfig Notice: Last index!")
      q=data[#data]
   elseif (keyIndex>#data) then
      print("interpConfig Error: keyIndex > len(data)!")
      q=data[#data]
      reset=true
   else
      for i=1,#q,1 do
         q[i]=data[keyIndex][i] + ((data[keyIndex+1][i]-data[keyIndex][i])/dt)*(tinterp-math.floor(tinterp/dt)*dt)
      end
   end
   -- print(string.format("t=%f, dt=%f, index=%d, q=(%f,%f,%f,%f,%f,%f)",tinterp,dt,keyIndex,q[1],q[2],q[3],q[4],q[5],q[6]))
   return reset,q
end

function setTimeSliderValue(ui,t)
   local fraction=t/(#jointData*nominalDT*(1/timeMult))
   simExtCustomUI_setSliderValue(ui,4000,10000*fraction,true)
   return
end

function playPressed(ui,id)
   local out=nil
   if not jointData then
      out=string.format("WARN: No file loaded, cannot play!")
      simExtCustomUI_setLabelText(ui, 1003, out)
      return
   end
   if (playbackStatus==status.stop) then
      startTime=simGetSimulationTime()
      out=string.format("Playback started from beginning!")
      simExtCustomUI_setLabelText(ui, 1003, out)
      playbackStatus=status.play
   elseif (playbackStatus==status.pause) then
      local tfrac=simExtCustomUI_getSliderValue(ui,4000)/10000
      startTime=simGetSimulationTime()-tfrac*(#jointData*nominalDT*(1/timeMult))
      out=string.format("Playback resuming from pause!")
      simExtCustomUI_setLabelText(ui, 1003, out)
      playbackStatus=status.play

   end
end


function pausePressed(ui,id)
   if (playbackStatus==status.play) then
      out=string.format("Playback paused!")
      simExtCustomUI_setLabelText(ui, 1003, out)
      playbackStatus=status.pause
   end
end


function stopPressed(ui,id)
   out=string.format("Playback stopped!")
   simExtCustomUI_setLabelText(ui, 1003, out)
   playbackStatus=status.stop
   setTimeSliderValue(ui, 0.0)
   if jointData then
      local reset,q = interpConfig(jointData, 0.0, (1/timeMult)*nominalDT)
      applyJoints(q)
   end
end


function stepPressed(ui,id)
   local reset=nil
   local q=nil
   local tfrac=nil
   local t=nil
   playbackStatus=status.pause
   out=string.format("Step!")
   simExtCustomUI_setLabelText(ui, 1003, out)
   tfrac=simExtCustomUI_getSliderValue(ui,4000)/10000
   tfrac=tfrac+0.005
   if (tfrac>=1.0) then tfrac=1.0 end
   t=tfrac*(#jointData*nominalDT*(1/timeMult))
   reset,q = interpConfig(jointData, t, (1/timeMult)*nominalDT)
   if jointData then applyJoints(q) end
   setTimeSliderValue(ui, t)
end


function timeSliderChange(ui,id,newVal)
   local t=nil
   local reset=nil
   local q=nil
   local resumePlay=false
   local out=""
   if (jointData == nil) then
      out=string.format("Need to open CSV file!")
      simExtCustomUI_setLabelText(ui, 1003, out)
      simExtCustomUI_setSliderValue(ui,4000,0,true)
      return
   end
   if (playbackStatus==status.play) then
      resumePlay=true
      playbackStatus=status.pause
   end
   t=(newVal/10000)*(#jointData*nominalDT*(1/timeMult))
   reset,q = interpConfig(jointData, t, (1/timeMult)*nominalDT)
   if jointData then applyJoints(q) end
   if (resumePlay) then
      playPressed(ui,1006)
   else
      playbackStatus=status.pause
   end
   out=string.format("Time slider dragged to %3.2f percent",newVal/10000)
   simExtCustomUI_setLabelText(ui, 1003, out)
   return
end


function decreaseSpeed(ui,id)
   local resumePlay=false
   if (playbackStatus==status.play) then
      resumePlay=true
      playbackStatus=status.pause
   end
   timeMult=timeMult-multStep
   if (timeMult <= multStep) then timeMult=multStep end
   if (resumePlay) then playPressed(ui,1006) end
   local out=string.format("%6.2f",timeMult)
   simExtCustomUI_setEditValue(ui, 1006, out)
end


function increaseSpeed(ui,id)
   local resumePlay=false
   if (playbackStatus==status.play) then
      resumePlay=true
      playbackStatus=status.pause
   end
   timeMult=timeMult+multStep
   if (resumePlay) then playPressed(ui,1006) end
   local out=string.format("%6.2f",timeMult)
   simExtCustomUI_setEditValue(ui, 1006, out)
end


function parseEnteredSpeed(ui,id,newVal)
   local q=tonumber(newVal)
   local out=nil
   local resumePlay=false
   if (q==nil) then
      out=string.format("Could not parse entered number!")
      simExtCustomUI_setLabelText(ui, 1003, out)
      return
   elseif (q<multStep) then
      q=multStep
      out=string.format("Minimum multiplier value is %3.2f!",multStep)
      simExtCustomUI_setLabelText(ui, 1003, out)
   end
   if (playbackStatus==status.play) then
      resumePlay=true
      playbackStatus=status.pause
   end
   timeMult=q
   if (resumePlay) then playPressed(ui,1006) end
   out=string.format("%6.2f",timeMult)
   simExtCustomUI_setEditValue(ui, 1006, out)
end


applyJoints=function(joints)
    for i=1,3,1 do
        simSetJointPosition(linear_h[i],joints[i])
        simSetJointPosition(passive_h[i],joints[i + 3])
        simSetJointPosition(bs_h[i],joints[i + 6])
    end
end

getJoints=function(jointHandles,angles)
   angles={0,0,0,0,0,0}
   for i=1,#jointHandles,1 do
      angles[i]=simGetJointPosition(jointHandles[i])
   end
   return angles
end

function mysplit(inputstr, sep)
   if sep == nil then
      sep = "%s"
   end
   local t={}
   for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
      table.insert(t,str)
   end
   return t
end

function closeEventHandler(h)
   simAddStatusbarMessage('Window '..h..' is closing...')
   simExtCustomUI_hide(h)
end

if (sim_call_type==sim_childscriptcall_initialization) then
   -- joint limits:
   --    1: (-360, 360)
   --    2: (-360, 360)
   --    3: (-360, 360)
   --    4: (-360, 360)
   --    5: (-360, 360)
   --    6: (-360, 360)

   xml = [[<ui closeable="false" onclose="closeEventHandler" resizable="true">
     <tabs>
       <tab title="CSV Playback">
         <group layout="vbox">
           <label text="<big> Enter CSV Filename:</big>" id="1000" wordwrap="false" style="font-weight: bold;"/>
           <group layout="hbox">
             <edit value="" id="1001" />
             <button text="Open File" onclick="parseCSVFile" id="2000" />
           </group>
           <label text="<big> Controls</big>" id="1005" wordwrap="false" style="font-weight: bold;"/>
           <group layout="grid">
             <button text="Play" onclick="playPressed" />
             <button text="Pause" onclick="pausePressed" />
             <button text="Stop" onclick="stopPressed" />
             <button text="Step" onclick="stepPressed" />
             <br/>
             <label text="Time Multiplier" />
             <button text="Increase" onclick="increaseSpeed" />
             <button text="Decrease" onclick="decreaseSpeed" />
             <edit id="1006" value="1.0" oneditingfinished="parseEnteredSpeed" />
           </group>
           <label text="Time" />
           <hslider id="4000" tick-position="below" tick-interval="500" minimum="0" maximum="10000" onchange="timeSliderChange"/>
           <label text="<big> Messages:</big>" id="1002" wordwrap="false" style="font-weight: bold;"/>
           <group layout="vbox">
              <label value="" id="1003" wordwrap="true" />
            </group>
          </group>
         <stretch />
       </tab>
     </tabs>
   </ui>]]

    consoleHandle = simAuxiliaryConsoleOpen('Debug CVS', 200, 1)
    simAuxiliaryConsolePrint(consoleHandle, 'This is a test!\n')
    ui=simExtCustomUI_create(xml)
    simAuxiliaryConsolePrint(consoleHandle, 'This is a test 2!\n')
    -- Store Joint Handles in List
    xyz={'x','y','z'}
    linear_h = {-1, -1, -1}
    passive_h = {-1, -1, -1}
    bs_h = {-1, -1, -1}
    for i=1,3,1 do
        linear_h[i]=simGetObjectHandle('stage_base_'..xyz[i])
        passive_h[i]=simGetObjectHandle('passive_stage_'..xyz[i])
        bs_h[i]=simGetObjectHandle('ball_socket_'..xyz[i])
    end
   -- constants for playback:
   timeMult=1.0
   multStep=0.2
   jointData=nil
   fname=""
   nominalDT=simGetSimulationTimeStep()
   startTime=0.0
   -- flags
   status={stop=0, play=1, pause=2}
   playbackStatus=status.stop
   delayCount=0
   delayRefCount=60

   -- setup:
   -- simExtCustomUI_setEditValue(ui, 1001, "/home/jarvis/work/me449_v-rep_demos/python/jointstates.csv")
end


if (sim_call_type==sim_childscriptcall_actuation) then
   local t=0.0
   local reset=nil
   local q=nil
   if (playbackStatus==status.play) then
      t=(simGetSimulationTime()-startTime)
      if (jointData) then
         reset,q = interpConfig(jointData, t, (1/timeMult)*nominalDT)
      else
         out=string.format("WARN: No file loaded, cannot play!")
         simExtCustomUI_setLabelText(ui, 1003, out)
      end
      if (reset) then
         if (delayCount>=delayRefCount) then
            startTime=simGetSimulationTime()
            out=string.format("Animation reset!")
            simExtCustomUI_setLabelText(ui, 1003, out)
            delayCount=0
         else
            out=string.format("CSV end!")
            simExtCustomUI_setLabelText(ui, 1003, out)
            delayCount=delayCount+1
         end
      end
      if (q) then
         applyJoints(q)
         setTimeSliderValue(ui,t)
      end
   end
end

if (sim_call_type==sim_childscriptcall_sensing) then

end

if (sim_call_type==sim_childscriptcall_cleanup) then
   simExtCustomUI_destroy(ui)
end
