----------------------------------------------------------------------------------------------------------------
-- Functions responsible for clearing the scene
----------------------------------------------------------------------------------------------------------------
function recursiveRemove(parentNode)
    local childList = simGetObjectsInTree(parentNode, sim_handle_all, 3)

    -- for i=1,#childList,1 do
    --      simAuxiliaryConsolePrint(consoleHandle, 'Child: '..simGetObjectName(childList[i])..'\n')
    -- end
    if #childList == 0 or childList == nil then
        simRemoveObject(parentNode)
    else
        for i=1,#childList,1 do
            recursiveRemove(childList[i])
        end
        simRemoveObject(parentNode)
    end
end

function clearScene(u, id)
    -- Get list of all first child shape objects in the scene.
    local objectList = simGetObjectsInTree(sim_handle_scene, sim_object_shape_type, 2)
    local jointList = simGetObjectsInTree(sim_handle_scene, sim_object_joint_type, 2)
    for i=1,#jointList,1 do
        objectList[#objectList + 1] = jointList[i]
    end
    -- for i=1,#objectList,1 do
    --      simAuxiliaryConsolePrint(consoleHandle, 'Child: '..simGetObjectName(objectList[i])..'\n')
    -- end
    local currHandle = -1
    for i=1,#objectList,1 do
        currHandle = objectList[i]
        childList = simGetObjectsInTree(currHandle, sim_handle_all, 1)
        if #childList == 0 then
            simRemoveObject(currHandle)
        else
            recursiveRemove(currHandle)
        end
    end
    paramLoaded = false
end

----------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------
-- Functions responsible for creating the different parts of the delta robot
----------------------------------------------------------------------------------------------------------------
function createBaseJoints()
    jointHandles = {} -- Global list of joint handles. Will be in the order of Leg 1, 2, 3
    local joint = nil
    for i=1,3,1 do
      local joint = simCreateJoint(sim_joint_revolute_subtype, sim_jointmode_force, 0)
      simSetObjectName(joint, "R"..tostring(i).."_B")
      jointHandles[i] = joint
    end
end

function createLinkJoints()
    linkJHandles = {} -- Global list of link universal joint handles. Will be in the order of Leg 1,2,3, 1,2,3. Parallel first half, Perpendicular last half
    local prlJoint = nil
    local ppdJoint = nil
    for i=1,3,1 do
      local prlJoint = simCreateJoint(sim_joint_revolute_subtype, sim_jointmode_force, 0)
      simSetObjectName(prlJoint, "U"..tostring(i).."_J_PRLB")
      linkJHandles[i] = prlJoint
    end
    for i=4,6,1 do
      local ppdJoint = simCreateJoint(sim_joint_revolute_subtype, sim_jointmode_force, 0)
      simSetObjectName(ppdJoint, "U"..tostring(i - 3).."_J_PPD")
      linkJHandles[i] = ppdJoint
    end
end

function createLinks(linkDiameter)
    linkHandles = {} -- Global list of link handles. Will be in the order of lower 1, 2, 3, upper, 1, 2, 3
    local link = nil
    for i=1,3,1 do -- Loop to create lower links
      link = simCreatePureShape(2,10,{linkDiameter, 0, modelParam.l1}, 1)
      simSetObjectName(link, "Link"..tostring(i).."_1")
      simSetObjectInt32Parameter(link, 3019,tonumber("1111000011111111",2))
      linkHandles[i] = link
    end

    for i=4,6,1 do -- Loop to create upper links
      link = simCreatePureShape(2,10,{linkDiameter, 0, modelParam.l2}, 1)
      simSetObjectName(link, "Link"..tostring(i - 3).."_2")
      simSetObjectInt32Parameter(link, 3019,tonumber("0000111111111111",2))
      linkHandles[i] = link
    end
end

function createJointConnect()
    jConnectHandles = {}
    local connect = nil
    for i=1,3,1 do -- Loop to create lower links
      connect = simCreatePureShape(1,10,{.02, 0, 0}, 1)
      simSetObjectName(connect, "Link"..tostring(i).."_Joint")
      simSetObjectInt32Parameter(connect, 3019,tonumber("0101010111111111",2))
      jConnectHandles[i] = connect
    end

    for i=4,6,1 do -- Loop to create upper links
      connect = simCreatePureShape(1,10,{.02, 0, 0}, 1)
      simSetObjectName(connect, "Link"..tostring(i - 3).."_EE_Joint")
      simSetObjectInt32Parameter(connect, 3019,tonumber("0101010110101010",2))
      jConnectHandles[i] = connect
    end
end

----------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------
-- Functions below are responsible for file IO for this script
--------------------------------------------------------------------------------------------------------------
function loadRobot(u, id)
   local param={}
   local out=""
   if file_exists() then
    out = string.format("File exists!")
    simExtCustomUI_setLabelText(ui, 1003, out)
   else
    out=string.format("Failed to parse!<br>Could not find file:<br>%s",fname)
    simExtCustomUI_setLabelText(ui, 1003, out)
    return nil
   end
   -- Now parse file into table:
   local i=1
   local parsedLine={}
   for line in io.lines(fname) do
      local key = string.match(line, "^(.*)%s=")
      local value = string.match(line, "%s(%.*%d*%s-)$")
      simAuxiliaryConsolePrint(consoleHandle,"key "..key..'\n')
      simAuxiliaryConsolePrint(consoleHandle,"value "..tostring(value)..'\n')
      param[key] = tonumber(value)
   end

   for k,v in pairs(param) do
      simAuxiliaryConsolePrint(consoleHandle,k.."   "..tostring(v)..'\n')
   end
   paramLoaded = true
   modelParam = param
end

function file_exists()
   fname = "deltaParams/delta.txt"
   local f=io.open(fname,"r")
   if f~=nil then io.close(f) return true else return false end
end

--------------------------------------------------------------------------------------------------------------

function closeEventHandler(h)
   simAddStatusbarMessage('Window '..h..' is closing...')
   simExtCustomUI_hide(h)
end

if (sim_call_type==sim_childscriptcall_initialization) then

   xml = [[<ui closeable="false" onclose="closeEventHandler" resizable="true">
     <tabs>
       <tab title="Create Delta Robot">

         <group layout="vbox">
           <group layout="hbox">
             <button text="Create Model" onclick="loadRobot" id="2000" />
             <button text="Clear Scene" onclick="clearScene" id="2001" />
           </group>

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
   ui=simExtCustomUI_create(xml)
   modelParam = {}
   paramLoaded = false
   modelCreated = false
   if(simGetObjectHandle('Delta_base') ~= nil) then
        base = simGetObjectHandle('Delta_base')
   end
end


if (sim_call_type==sim_childscriptcall_actuation) then
  if paramLoaded then
      -- Setting up static variables
      local plateThickness = .05
      local centerPlate = plateThickness/2
      local linkDiameter = .02
      local baseDiameter = modelParam.r1*2
      local eeDiameter = modelParam.r2*2
      local eeHeight = modelParam.l1 + modelParam.l2

      -- Base Location Variable
      local basePos = {0,0,centerPlate}
      local eePos = {0,0,eeHeight}

      -- Joint Locations
          -- Base
      local r1Pos = {0,-modelParam.r1,centerPlate}
      local r2Pos = {modelParam.r1*math.sqrt(3)/2,modelParam.r1*.5,centerPlate}
      local r3Pos = {-modelParam.r1*math.sqrt(3)/2,modelParam.r1*.5,centerPlate}
          -- Link Universal Joints
      local uJ1Pos = {0,-modelParam.r1,centerPlate + modelParam.l1}
      local uJ2Pos = {modelParam.r1*math.sqrt(3)/2,modelParam.r1*.5,centerPlate + modelParam.l1}
      local uJ3Pos = {-modelParam.r1*math.sqrt(3)/2,modelParam.r1*.5,centerPlate + modelParam.l1}
          -- EE Universal Joints

      -- Joint Orientations
      local prlb1 = {0, -math.pi/2, -math.pi/2}
      local prlb2 = {math.pi/2, math.pi/6, 0}
      local prlb3 = {-math.pi/2, math.pi/6, -math.pi}

      local ppdbU1 = {math.pi/2, 0, 0}
      local ppdbU2 = {-math.pi/2, math.pi/3, -math.pi}
      local ppdbU3 = {math.pi/2, math.pi/3, 0}

      -- Lower Link Location Variables
      local lowPos1 = {0,-modelParam.r1,centerPlate + modelParam.l1/2}
      local lowPos2 = {modelParam.r1*math.sqrt(3)/2,modelParam.r1*.5,centerPlate + modelParam.l1/2}
      local lowPos3 = {-modelParam.r1*math.sqrt(3)/2,modelParam.r1*.5,centerPlate + modelParam.l1/2}

      -- Upper Link Location Variables
      local upPos1 = {0,-modelParam.r1,centerPlate + modelParam.l1 + modelParam.l2/2}
      local upPos2 = {modelParam.r1*math.sqrt(3)/2,modelParam.r1*.5,centerPlate + modelParam.l1 + modelParam.l2/2}
      local upPos3 = {-modelParam.r1*math.sqrt(3)/2,modelParam.r1*.5,centerPlate + modelParam.l1  + modelParam.l2/2}

      --Add Base
      base = simCreatePureShape(2,10,{baseDiameter, 0, plateThickness}, 1)
      simSetObjectPosition(base, -1, basePos)
      simSetObjectName(base, 'Delta_base')
      simSetObjectInt32Parameter(base, 3019,tonumber("1111111111111111",2))

      --Add ee
      ee = simCreatePureShape(2,10,{eeDiameter, 0, plateThickness}, 1)
      simSetObjectPosition(ee, -1, eePos)
      simSetObjectName(ee, 'Delta_ee')
      simSetObjectParent(ee, base, 1)
      simSetObjectInt32Parameter(ee, 3019,tonumber("1010101011111111",2))

      --Create and move Base Joints: Array jointHandles
      createBaseJoints()
      simSetObjectPosition(jointHandles[1], -1, r1Pos) --Joint 1
      simSetObjectParent(jointHandles[1], base, 1)
      simSetObjectOrientation(jointHandles[1], -1, prlb1)

      simSetObjectPosition(jointHandles[2], -1, r2Pos) --Joint 2
      simSetObjectParent(jointHandles[2], base, 1)
      simSetObjectOrientation(jointHandles[2], -1, prlb2)

      simSetObjectPosition(jointHandles[3], -1, r3Pos) --Joint 3
      simSetObjectParent(jointHandles[3], base, 1)
      simSetObjectOrientation(jointHandles[3], -1, prlb3)

      --Create links. Respondable masks are already set up for these links from function.
      createLinks(linkDiameter)

      --Move lower links: Array linkHandles[1-3]
      simSetObjectPosition(linkHandles[1], -1, lowPos1) --Lower Link 1
      simSetObjectParent(linkHandles[1], jointHandles[1], 1)

      simSetObjectPosition(linkHandles[2], -1, lowPos2) --Lower Link 1
      simSetObjectParent(linkHandles[2], jointHandles[2], 1)

      simSetObjectPosition(linkHandles[3], -1, lowPos3) --Lower Link 1
      simSetObjectParent(linkHandles[3], jointHandles[3], 1)

      --Create link universal joints
      createLinkJoints()

      --Move parallel joints first: Array linkJHandles[1-3]
      simSetObjectPosition(linkJHandles[1], -1, uJ1Pos) --Joint 1
      simSetObjectParent(linkJHandles[1], linkHandles[1], 1)
      simSetObjectOrientation(linkJHandles[1], -1, prlb1)

      simSetObjectPosition(linkJHandles[2], -1, uJ2Pos) --Joint 2
      simSetObjectParent(linkJHandles[2], linkHandles[2], 1)
      simSetObjectOrientation(linkJHandles[2], -1, prlb2)

      simSetObjectPosition(linkJHandles[3], -1, uJ3Pos) --Joint 3
      simSetObjectParent(linkJHandles[3], linkHandles[3], 1)
      simSetObjectOrientation(linkJHandles[3], -1, prlb3)

      -- Create joint connectors for universal joints
      createJointConnect()

      --Move joint connectors next: Array jConnectHandles
      simSetObjectPosition(jConnectHandles[1], -1, uJ1Pos) --Joint 1
      simSetObjectParent(jConnectHandles[1], linkJHandles[1], 1)
      simSetObjectOrientation(jConnectHandles[1], -1, prlb1)

      simSetObjectPosition(jConnectHandles[2], -1, uJ2Pos) --Joint 2
      simSetObjectParent(jConnectHandles[2], linkJHandles[2], 1)
      simSetObjectOrientation(jConnectHandles[2], -1, prlb2)

      simSetObjectPosition(jConnectHandles[3], -1, uJ3Pos) --Joint 3
      simSetObjectParent(jConnectHandles[3], linkJHandles[3], 1)
      simSetObjectOrientation(jConnectHandles[3], -1, prlb3)

      --Move perpendicular joints to create universal: Array linkJHandles[4-6]
      simSetObjectPosition(linkJHandles[4], -1, uJ1Pos) --Joint 1
      simSetObjectParent(linkJHandles[4], jConnectHandles[1], 1)
      simSetObjectOrientation(linkJHandles[4], -1, ppdbU1)

      simSetObjectPosition(linkJHandles[5], -1, uJ2Pos) --Joint 2
      simSetObjectParent(linkJHandles[5], jConnectHandles[2], 1)
      simSetObjectOrientation(linkJHandles[5], -1, ppdbU2)

      simSetObjectPosition(linkJHandles[6], -1, uJ3Pos) --Joint 3
      simSetObjectParent(linkJHandles[6], jConnectHandles[3], 1)
      simSetObjectOrientation(linkJHandles[6], -1, ppdbU3)

      --Move upper links: Array linkHandles[4-6]
      simSetObjectPosition(linkHandles[4], -1, upPos1) --Lower Link 1
      simSetObjectParent(linkHandles[4], linkJHandles[4], 1)

      simSetObjectPosition(linkHandles[5], -1, upPos2) --Lower Link 1
      simSetObjectParent(linkHandles[5], linkJHandles[5], 1)

      simSetObjectPosition(linkHandles[6], -1, upPos3) --Lower Link 1
      simSetObjectParent(linkHandles[6], linkJHandles[6], 1)
      paramLoaded = false
  end
end

if (sim_call_type==sim_childscriptcall_sensing) then

end

if (sim_call_type==sim_childscriptcall_cleanup) then
   simExtCustomUI_destroy(ui)
end
