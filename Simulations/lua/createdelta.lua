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
    modelCreated = false
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
      simSetObjectInt32Parameter(joint, 2000,1) --Enables motor
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
      simSetObjectInt32Parameter(prlJoint, 2000,1) --Enables motor
      linkJHandles[i] = prlJoint
    end
    for i=4,6,1 do
      local ppdJoint = simCreateJoint(sim_joint_revolute_subtype, sim_jointmode_force, 0)
      simSetObjectName(ppdJoint, "U"..tostring(i - 3).."_J_PPDB")
      simSetObjectInt32Parameter(ppdJoint, 2000,1) --Enables motor
      simSetJointInterval(ppdJoint, false, {-math.pi/4, math.pi/2})
      linkJHandles[i] = ppdJoint
    end
end

function createEEJoints()
    eeJHandles = {} -- Global list of ee universal joint handles. Will be in the order of Leg 1,2,3, 1,2,3. Parallel first half, Perpendicular last half
    local prlJoint = nil
    local ppdJoint = nil
    for i=1,3,1 do
      local prlJoint = simCreateJoint(sim_joint_revolute_subtype, sim_jointmode_force, 0)
      simSetObjectName(prlJoint, "U"..tostring(i).."_EE_PRLB")
      simSetObjectInt32Parameter(prlJoint, 2000,1)
      eeJHandles[i] = prlJoint
    end
    for i=4,6,1 do
      local ppdJoint = simCreateJoint(sim_joint_revolute_subtype, sim_jointmode_force, 0)
      simSetObjectName(ppdJoint, "U"..tostring(i - 3).."_EE_PPDB")
      simSetObjectInt32Parameter(ppdJoint, 2000,1)
      simSetJointInterval(ppdJoint, false, {-math.pi/4, math.pi/2})
      eeJHandles[i] = ppdJoint
    end
end

function createLinks(linkDiameter)
    linkHandles = {} -- Global list of link handles. Will be in the order of lower 1, 2, 3, upper, 1, 2, 3
    local link = nil
    for i=1,3,1 do -- Loop to create lower links
      link = simCreatePureShape(2,10,{linkDiameter, 0, modelParam.l1}, 1)
      simSetObjectName(link, "Link"..tostring(i).."_1")
      simSetObjectInt32Parameter(link, 3019,tonumber("1111111100001111",2))
      simSetShapeMassAndInertia(link,1, {1,0,0,0,1,0,0,0,1}, simGetObjectPosition(link, -1))
      linkHandles[i] = link
    end

    for i=4,6,1 do -- Loop to create upper links
      link = simCreatePureShape(2,10,{linkDiameter, 0, modelParam.l2}, 1)
      simSetObjectName(link, "Link"..tostring(i - 3).."_2")
      simSetObjectInt32Parameter(link, 3019,tonumber("1111111111110000",2))
      simSetShapeMassAndInertia(link,1, {1,0,0,0,1,0,0,0,1}, simGetObjectPosition(link, -1))
      linkHandles[i] = link
    end
end

function createJointConnect()
    jConnectHandles = {}
    local connect = nil
    for i=1,3,1 do -- Loop to link universal connector
      connect = simCreatePureShape(1,2,{.02, 0, 0}, 1)
      simSetObjectName(connect, "Link"..tostring(i).."_Joint")
      simSetObjectInt32Parameter(connect, 3019,tonumber("1111111101010101",2))
      simSetShapeMassAndInertia(connect,1, {1,0,0,0,1,0,0,0,1}, simGetObjectPosition(connect, -1))
      simSetObjectInt32Parameter(connect, 3004,0)
      jConnectHandles[i] = connect
    end

    for i=4,6,1 do -- Loop to end effector universal connector
      connect = simCreatePureShape(1,10,{.02, 0, 0}, 1)
      simSetObjectName(connect, "Link"..tostring(i - 3).."_EE_Joint")
      simSetObjectInt32Parameter(connect, 3019,tonumber("1010101001010101",2))
      simSetShapeMassAndInertia(connect,1, {1,0,0,0,1,0,0,0,1}, simGetObjectPosition(connect, -1))
      simSetObjectInt32Parameter(connect, 3004,0)
      jConnectHandles[i] = connect
    end
end

function createDummy()
    dummyHandles = {} -- List will be in order of Tip 1, 2, 3, Target 1, 2, 3
    local dummy = nil
    for i=1,3,1 do -- Create tip dummies
      dummy = simCreateDummy(.02)
      simSetObjectName(dummy,"Link"..tostring(i).."_tip")
      simSetObjectInt32Parameter(dummy, 10000,sim_dummy_linktype_dynamics_loop_closure)
      dummyHandles[i] = dummy
    end
    for i=4,6,1 do -- Create target dummies
      dummy = simCreateDummy(.02)
      simSetObjectName(dummy,"Link"..tostring(i - 3).."_target")
      simSetObjectInt32Parameter(dummy, 10000,sim_dummy_linktype_dynamics_loop_closure)
      dummyHandles[i] = dummy
    end

    for i=1,3,1 do --Connect tip and target together using dynamics overlap constraint
        simSetLinkDummy(dummyHandles[i], dummyHandles[i + 3])
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
      -- simAuxiliaryConsolePrint(consoleHandle,"key "..key..'\n')
      -- simAuxiliaryConsolePrint(consoleHandle,"value "..tostring(value)..'\n')
      param[key] = tonumber(value)
   end

   -- for k,v in pairs(param) do
   --    simAuxiliaryConsolePrint(consoleHandle,k.."   "..tostring(v)..'\n')
   -- end

   paramLoaded = true
   modelParam = param
end

function file_exists()
   fname = "deltaParams/delta.txt"
   local f=io.open(fname,"r")
   if f~=nil then io.close(f) return true else return false end
end

--------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------
-- Functions below are responsible for saving the model
--------------------------------------------------------------------------------------------------------------
function saveModel(u,id)
  if base ~= nil then
    local filename = simExtCustomUI_getEditValue(ui,2003)
    if filename == "Save model as..." then
      local out = string.format("Invalid filename. Please enter a filename!")
      simExtCustomUI_setLabelText(ui, 1003, out)
    else
      local file = 'deltaModels/'..filename..'.ttm'
      local result = simSaveModel(base, file)
      local out = string.format("Model Saved! Saved as "..file..'\n')
    simExtCustomUI_setLabelText(ui, 1003, out)
    end
  else
    local out = string.format("Model not created. Cannot save!")
    simExtCustomUI_setLabelText(ui, 1003, out)
  end

end

---------------------------------------------------------------------------------------------------------------
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
             <button text="Save Model"  onclick="saveModel" id="2002" />
             <edit value="Save model as..."   id="2003" />
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
   -------Supressing error to check if object exists-----------
   local savedMode=simGetIntegerParameter(sim_intparam_error_report_mode)
   simSetIntegerParameter(sim_intparam_error_report_mode,0)

   local modeltest = simGetObjectHandle('Delta_base')

   simSetIntegerParameter(sim_intparam_error_report_mode,savedMode)
   -------Supressing error to check if object exists-----------

   if(modeltest ~= -1) then
        base = simGetObjectHandle('Delta_base')
        modelCreated = true
   else
        base = nil
        simAuxiliaryConsolePrint(consoleHandle,"No model found!\n")
   end
end


if (sim_call_type==sim_childscriptcall_actuation) then
  if paramLoaded and not modelCreated then
      -- Setting up static variables
      local plateThickness = .05
      local centerPlate = plateThickness/2
      local linkDiameter = .02
      local baseDiameter = modelParam.r1*2
      local eeDiameter = modelParam.r2*2
      --local eeHeight = modelParam.l1 + modelParam.l2
      local initialAngle = math.pi/9
      local eeHeight = modelParam.l1*math.cos(-initialAngle) + modelParam.l2*math.cos(initialAngle)

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
      local eePRLJ1Pos = {0,-modelParam.r2,eeHeight}
      local eePRLJ2Pos = {modelParam.r2*math.sqrt(3)/2,modelParam.r2*.5,eeHeight}
      local eePRLJ3Pos = {-modelParam.r2*math.sqrt(3)/2,modelParam.r2*.5,eeHeight}

      local eePPDJ1Pos = {0,-modelParam.r1,centerPlate + modelParam.l1 + modelParam.l2}
      local eePPDJ2Pos = {modelParam.r1*math.sqrt(3)/2,modelParam.r1*.5,centerPlate + modelParam.l1 + modelParam.l2}
      local eePPDJ3Pos = {-modelParam.r1*math.sqrt(3)/2,modelParam.r1*.5,centerPlate + modelParam.l1  + modelParam.l2}

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
      base = simCreatePureShape(2,10,{baseDiameter, 0, plateThickness}, 100)
      simSetObjectPosition(base, -1, basePos)
      simSetObjectName(base, 'Delta_base')
      simSetObjectInt32Parameter(base, 3019,tonumber("1111111111111111",2))
      simSetShapeMassAndInertia(base,100, {100,0,0,0,100,0,0,0,100}, simGetObjectPosition(base, -1))

      --Add ee
      ee = simCreatePureShape(2,10,{eeDiameter, 0, plateThickness}, 1)
      simSetObjectPosition(ee, -1, eePos)
      simSetObjectName(ee, 'Delta_ee')
      simSetObjectParent(ee, base, 1)
      simSetObjectInt32Parameter(ee, 3019,tonumber("1111111110101010",2))
      simSetShapeMassAndInertia(ee,1, {1,0,0,0,1,0,0,0,1}, simGetObjectPosition(ee, -1))

      --Create and move Base Joints: Array jointHandles
      createBaseJoints()
      simSetObjectPosition(jointHandles[1], -1, r1Pos) --Joint 1
      simSetObjectParent(jointHandles[1], base, 1)
      simSetObjectOrientation(jointHandles[1], -1, prlb1)
      simSetJointPosition(jointHandles[1], 0)
      simSetJointForce(jointHandles[1], 50)
      simSetObjectInt32Parameter(jointHandles[1], 2030,1) --Lock Motor when target velocity is 0

      simSetObjectPosition(jointHandles[2], -1, r2Pos) --Joint 2
      simSetObjectParent(jointHandles[2], base, 1)
      simSetObjectOrientation(jointHandles[2], -1, prlb2)
      simSetJointPosition(jointHandles[2], 0)
      simSetJointForce(jointHandles[2], 50)
      simSetObjectInt32Parameter(jointHandles[2], 2030,1)

      simSetObjectPosition(jointHandles[3], -1, r3Pos) --Joint 3
      simSetObjectParent(jointHandles[3], base, 1)
      simSetObjectOrientation(jointHandles[3], -1, prlb3)
      simSetJointPosition(jointHandles[3], 0)
      simSetJointForce(jointHandles[3], 50)
      simSetObjectInt32Parameter(jointHandles[3], 2030,1)

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

      --Move joint connectors next: Array jConnectHandles[1-3]
      simSetObjectPosition(jConnectHandles[1], -1, uJ1Pos) --Joint 1
      simSetObjectParent(jConnectHandles[1], linkJHandles[1], 1)
      simSetObjectOrientation(jConnectHandles[1], sim_handle_parent, {0,0,0})

      simSetObjectPosition(jConnectHandles[2], -1, uJ2Pos) --Joint 2
      simSetObjectParent(jConnectHandles[2], linkJHandles[2], 1)
      simSetObjectOrientation(jConnectHandles[2], sim_handle_parent, {0,0,0})

      simSetObjectPosition(jConnectHandles[3], -1, uJ3Pos) --Joint 3
      simSetObjectParent(jConnectHandles[3], linkJHandles[3], 1)
      simSetObjectOrientation(jConnectHandles[3], sim_handle_parent, {0,0,0})

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

      -- Create ee joints
      createEEJoints()

      --Move ee_joints to end of leg: Array eeJHandles[4-6]
      simSetObjectPosition(eeJHandles[4], -1, eePPDJ1Pos) --Joint 1
      simSetObjectParent(eeJHandles[4], linkHandles[4], 1)
      simSetObjectOrientation(eeJHandles[4], -1, ppdbU1)

      simSetObjectPosition(eeJHandles[5], -1, eePPDJ2Pos) --Joint 2
      simSetObjectParent(eeJHandles[5], linkHandles[5], 1)
      simSetObjectOrientation(eeJHandles[5], -1, ppdbU2)

      simSetObjectPosition(eeJHandles[6], -1, eePPDJ3Pos) --Joint 3
      simSetObjectParent(eeJHandles[6], linkHandles[6], 1)
      simSetObjectOrientation(eeJHandles[6], -1, ppdbU3)

      --Move ee_joints to end effector: Array eeJHandles[1-3]
      simSetObjectPosition(eeJHandles[1], -1, eePRLJ1Pos) --Joint 1
      simSetObjectParent(eeJHandles[1], ee, 1)
      simSetObjectOrientation(eeJHandles[1], -1, prlb1)

      simSetObjectPosition(eeJHandles[2], -1, eePRLJ2Pos) --Joint 2
      simSetObjectParent(eeJHandles[2], ee, 1)
      simSetObjectOrientation(eeJHandles[2], -1, prlb2)

      simSetObjectPosition(eeJHandles[3], -1, eePRLJ3Pos) --Joint 3
      simSetObjectParent(eeJHandles[3], ee, 1)
      simSetObjectOrientation(eeJHandles[3], -1, prlb3)

      --Move joint connectors to end effector: Array jConnectHandles[4-6]
      simSetObjectPosition(jConnectHandles[4], -1, eePRLJ1Pos) --Joint 1
      simSetObjectParent(jConnectHandles[4], eeJHandles[1], 1)
      simSetObjectOrientation(jConnectHandles[4], sim_handle_parent, {0,0,0})

      simSetObjectPosition(jConnectHandles[5], -1, eePRLJ2Pos) --Joint 2
      simSetObjectParent(jConnectHandles[5], eeJHandles[2], 1)
      simSetObjectOrientation(jConnectHandles[5], sim_handle_parent, {0,0,0})

      simSetObjectPosition(jConnectHandles[6], -1, eePRLJ3Pos) --Joint 3
      simSetObjectParent(jConnectHandles[6], eeJHandles[3], 1)
      simSetObjectOrientation(jConnectHandles[6], sim_handle_parent, {0,0,0})

      --Create dummy for connecting legs to end effector
      createDummy()

      --Move dummy tip and targets to respective places. Legs will hold tip while EE will hold target: Array dummyHandles
      simSetObjectPosition(dummyHandles[4], -1, eePRLJ1Pos) --Leg 1 target
      simSetObjectParent(dummyHandles[4], jConnectHandles[4], 1)
      simSetObjectOrientation(dummyHandles[4], sim_handle_parent, {0,0,0})

      simSetObjectPosition(dummyHandles[5], -1, eePRLJ2Pos) --Leg 2 target
      simSetObjectParent(dummyHandles[5], jConnectHandles[5], 1)
      simSetObjectOrientation(dummyHandles[5], sim_handle_parent, {0,0,0})

      simSetObjectPosition(dummyHandles[6], -1, eePRLJ3Pos) --Leg 3 target
      simSetObjectParent(dummyHandles[6], jConnectHandles[6], 1)
      simSetObjectOrientation(dummyHandles[6], sim_handle_parent, {0,0,0})

      simSetObjectPosition(dummyHandles[1], -1, eePPDJ1Pos) --Leg 1 tip
      simSetObjectParent(dummyHandles[1], eeJHandles[4], 1)
      simSetObjectOrientation(dummyHandles[1], -1, simGetObjectOrientation(dummyHandles[4], -1))

      simSetObjectPosition(dummyHandles[2], -1, eePPDJ2Pos) --Leg 2 tip
      simSetObjectParent(dummyHandles[2], eeJHandles[5], 1)
      simSetObjectOrientation(dummyHandles[2], -1, simGetObjectOrientation(dummyHandles[5], -1))

      simSetObjectPosition(dummyHandles[3], -1, eePPDJ3Pos) --Leg 3 tip
      simSetObjectParent(dummyHandles[3], eeJHandles[6], 1)
      simSetObjectOrientation(dummyHandles[3], -1, simGetObjectOrientation(dummyHandles[6], -1))

      -- Move base and link joints to approximately move tip near target for smoother dynamics transition
      simSetJointPosition(jointHandles[1], -initialAngle)
      simSetJointPosition(jointHandles[2], -initialAngle)
      simSetJointPosition(jointHandles[3], -initialAngle)

      simSetJointPosition(linkJHandles[1],math.pi/4)
      simSetJointPosition(linkJHandles[2],math.pi/4)
      simSetJointPosition(linkJHandles[3],math.pi/4)

      -- Set base to be the model base. Allows for saving the model.
      local modelProp = simGetModelProperty(base)
      simSetModelProperty(base, simBoolOr32(modelProp, sim_modelproperty_not_model)-sim_modelproperty_not_model)
      modelCreated = true
  end
end

if (sim_call_type==sim_childscriptcall_sensing) then

end

if (sim_call_type==sim_childscriptcall_cleanup) then
   simExtCustomUI_destroy(ui)
end
