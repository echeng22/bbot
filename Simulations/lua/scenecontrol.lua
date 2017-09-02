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
    modelLoaded = false
    ROSSetup = false
    ROSCom = false
end

------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- Functions responsible for getting model properties and state information
------------------------------------------------------------------------------------------------------------------

function getDimensions(objectHandle)
    -- Returns the dimensions of an object given its object handle.
    --      Returns as: {radius, length}
    -- This function assumes that object being looked at is of pure shape cylinder. This is because
    -- the relevant information of this model is only in cylinder shapes.
    --      xSize: Diameter of the cylinder
    --      ySize: Diameter of the cylinder (redundant)
    --      zSize: Length/Height of the cylinder
    local localxMinMax={0,0}
    local localyMinMax={0,0}
    local localzMinMax={0,0}
    local result = nil
    result,localxMinMax[1]=simGetObjectFloatParameter(objectHandle,15)
    result,localyMinMax[1]=simGetObjectFloatParameter(objectHandle,16)
    result,localzMinMax[1]=simGetObjectFloatParameter(objectHandle,17)
    result,localxMinMax[2]=simGetObjectFloatParameter(objectHandle,18)
    result,localyMinMax[2]=simGetObjectFloatParameter(objectHandle,19)
    result,localzMinMax[2]=simGetObjectFloatParameter(objectHandle,20)
    local xSize=localxMinMax[2]-localxMinMax[1]
    local ySize=localyMinMax[2]-localyMinMax[1]
    local zSize=localzMinMax[2]-localzMinMax[1]
    -- simAuxiliaryConsolePrint(consoleHandle,"xSize: "..tostring(xSize)..'\n')
    -- simAuxiliaryConsolePrint(consoleHandle,"ySize: "..tostring(ySize)..'\n')
    -- simAuxiliaryConsolePrint(consoleHandle,"zSize: "..tostring(zSize)..'\n')
    return {xSize/2, zSize}
end


------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- Functions responsible for starting/stopping ROS Communication
------------------------------------------------------------------------------------------------------------------

function startROS(u, id)
    if not modelLoaded then
        ROSCom = false
        out = string.format("Model Not Loaded! Cannot start ROS Communication!")
        simExtCustomUI_setLabelText(ui, 1003, out)
    else
        ROSCom = true
        publishModelParam()
    end

end

function stopROS(u, id)
    ROSCom = false
end

------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- setUpROS(): Responsible for setting up publishers/subscribers of joint states for the model
-- Also will be responsible for setting up handles for joints
-- Sets up:
--      robotHandle: handle of delta robot
--      robotName: name of delta robot
--      rosInterfacePresent: variable that tells if rosInterface is set up
--      revJointList: list that holds handle of active robot revolute joints. Order of Joints 1, 2, 3
--      jointpub: joint state publisher
--      timepub: simulation time publisher
--      jointsub: joint velocity subscriber
--
-- setUpParams(): Responsible for setting up model parameter values to ROS parameter server. Values that
-- are set up currently include: the radius of the base, radius of the end-effector, length of lower link
-- and lenght of upper link.
-- Sets up:
--      rBase: radius of base
--      rEE: radius of end-effector
--      lowerLink: length of lower link
--      upperLink: length of upper link
------------------------------------------------------------------------------------------------------------------
function setUpROS()
    robotHandle = simGetObjectHandle("Delta_base")
    robotName = "Delta_base"

    --Check if required RosInterface is there:
    moduleName = 0
    index = 0
    rosInterfacePresent = false
    while moduleName do
        moduleName = simGetModuleName(index)
        if(moduleName == 'RosInterface') then
            rosInterfacePresent = true
        end
        index = index+1
    end
    if rosInterfacePresent then
        revJointList = {simGetObjectHandle("R1_B"),simGetObjectHandle("R2_B"),simGetObjectHandle("R3_B")}
        revJointName = {}
        for i=1,#revJointList,1        do
            revJointName[i] = simGetObjectName(revJointList[i]);
        end
    end

    jointpub = simExtRosInterface_advertise('/Delta_base/rev_joint','sensor_msgs/JointState')
    eePospub = simExtRosInterface_advertise('/Delta_base/ee_pos','geometry_msgs/Pose')
    timepub = simExtRosInterface_advertise('/simulationTime','std_msgs/Float32')
    modepub = simExtRosInterface_advertise('/eeMode','std_msgs/Bool')
    -- jointsub = simExtRosInterface_subscribe('/Delta_base/desired_joint_pos','sensor_msgs/JointState', 'jointsub_callback')
    jointVelSub = simExtRosInterface_subscribe('/Delta_base/joint_vel','sensor_msgs/JointState', 'jointVelSub_callback')

    baseParamPub = simExtRosInterface_advertise('/Delta_base/base_radius','std_msgs/Float64')
    eeParamPub = simExtRosInterface_advertise('/Delta_base/ee_radius','std_msgs/Float64')
    lowLinkParamPub = simExtRosInterface_advertise('/Delta_base/lower_link','std_msgs/Float64')
    upLinkParamPub = simExtRosInterface_advertise('/Delta_base/upper_link','std_msgs/Float64')


end

function publishModelParam()
    local base_values = getDimensions(base)
    local ee_values = getDimensions(simGetObjectHandle("Delta_ee"))
    local lowlink_values = getDimensions(simGetObjectHandle("Link1_1"))
    local uplink_values = getDimensions(simGetObjectHandle("Link1_2"))

    simExtRosInterface_publish(baseParamPub, {data = base_values[1]})
    simExtRosInterface_publish(eeParamPub, {data = ee_values[1]})
    simExtRosInterface_publish(lowLinkParamPub, {data = lowlink_values[2]})
    simExtRosInterface_publish(upLinkParamPub, {data = uplink_values[2]})
end
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- Functions responsible for setting up ROS messages
------------------------------------------------------------------------------------------------------------------
function getHeader()
    return {header = {stamp=simGetSystemTime()}}
end

function jointVelSub_callback(jointData)
    local name = jointData.name
    local velocity = jointData.velocity
    for i=1,#name,1
    do
        local handle = simGetObjectHandle(name[i])
        simSetJointTargetVelocity(handle, velocity[i])
    end
end

function jointsub_callback(jointData)
    local name = jointData.name
    local angle = jointData.position
    for i=1,#name,1
    do
        local handle = simGetObjectHandle(name[i])
        simSetJointTargetPosition(handle, angle[i])
    end
end

function getJointPositions()
    local posList = {}
    for i=1,#revJointList,1
    do
        posList[i] = simGetJointPosition(revJointList[i]);
    end
    return posList
end

function getEEPos()
    local eeHandle = simGetObjectHandle("Delta_ee")
    return simGetObjectPosition(eeHandle, -1)
end

function changeMode()
    mode = not mode
end

------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- Functions responsible for loading delta robot model into scene
------------------------------------------------------------------------------------------------------------------
function loadDelta(u, id)
    local filename = simExtCustomUI_getEditValue(ui,2005)
    local f=io.open("deltaModels/"..filename)
    if f == nil then
        out = string.format("File does NOT exist! Please type correct file name.")
        simExtCustomUI_setLabelText(ui, 1003, out)
    else
        io.close(f);
        local model = simLoadModel("deltaModels/"..filename)
        out = string.format("File exists!")
        simExtCustomUI_setLabelText(ui, 1003, out)
        base = model
        -- simAuxiliaryConsolePrint(consoleHandle, tostring(base)..'\n')
        -- simAuxiliaryConsolePrint(consoleHandle, simGetObjectName(base)..'\n')
        modelLoaded = true
    end
end

------------------------------------------------------------------------------------------------------------------

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
             <button text="Clear Scene" onclick="clearScene" id="2000" />
             <button text="Start ROS COM" onclick="startROS" id="2001" />
             <button text="Stop ROS COM" onclick="stopROS" id="2002" />
             <button text="Change EE Mode" onclick="changeMode" id="2003" />
             <button text="Load Model" onclick="loadDelta" id="2004" />
             <edit value="Model name from delta model folder..."   id="2005" />
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
   -- consoleHandle = simAuxiliaryConsoleOpen('Debug CVS', 200, 1)
   -- simAuxiliaryConsolePrint(consoleHandle,"test\n")
   ui=simExtCustomUI_create(xml)
   ROSCom = false
   ROSSetup = false
   modelLoaded = false
   mode = false
   -------Supressing error to check if object exists-----------
   local savedMode=simGetIntegerParameter(sim_intparam_error_report_mode)
   simSetIntegerParameter(sim_intparam_error_report_mode,0)

   local modeltest = simGetObjectHandle('Delta_base')

   simSetIntegerParameter(sim_intparam_error_report_mode,savedMode)
   -------Supressing error to check if object exists-----------
   if (modeltest ~= -1) then
        base = simGetObjectHandle('Delta_base')
        modelLoaded = true
   else
        base = nil
        simAuxiliaryConsolePrint(consoleHandle,"No model found!\n")
   end
end

if (sim_call_type==sim_childscriptcall_actuation) then
    if modelLoaded and not ROSSetup then
        setUpROS()
        ROSSetup = true
    end
    if rosInterfacePresent and ROSCom then
        local jointInfo = getHeader()
        jointInfo["name"] = revJointName
        jointInfo["position"] = getJointPositions() -- Joint angles are in radians.

        local eeVal = getEEPos()
        local eePos = {}
        local eePoint = {}
        eePoint["x"] = eeVal[1]
        eePoint["y"] = eeVal[2]
        eePoint["z"] = eeVal[3]
        eePos["position"] = eePoint
        -- jointInfo["velocity"] = simGetObjectName(joint)
        -- jointInfo["effort"] = simGetObjectName(joint)
        simExtRosInterface_publish(timepub, {data = simGetSimulationTime()})
        simExtRosInterface_publish(jointpub, jointInfo)
        simExtRosInterface_publish(modepub, {data = mode})
        simExtRosInterface_publish(eePospub, eePos)
    end
end


if (sim_call_type==sim_childscriptcall_sensing) then

    -- Put your main SENSING code here

end


if (sim_call_type==sim_childscriptcall_cleanup) then

    -- Put some restoration code here

end

