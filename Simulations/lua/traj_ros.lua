function getHeader()
    return {header = {stamp=simGetSystemTime()}}
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

function jointvel_callback(velData)
    local name = velData.name
    local velocity = velData.velocity
    for i=1,#name,1
    do
        local handle = simGetObjectHandle(name[i])
        simSetJointTargetVelocity(handle, velocity[i])
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

function getEEPose()
    local eePos = simGetObjectPosition(eeHandle, robotObjectList[1])
    local pose = {position = {x = eePos[1], y = eePos[2], z = eePos[3]}, orientation = {x = 1, y = 1, z = 1, w = 1}} --Quaternions are dummy values, as we don't consider orientation right now
    return pose
end


if (sim_call_type==sim_childscriptcall_initialization) then
    -- Child Script Initialization
    robotHandle = simGetObjectAssociatedWithScript(sim_handle_self)
    robotName = simGetObjectName(robotHandle)

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
    consoleHandle = simAuxiliaryConsoleOpen('Debug CVS', 200, 1)
    --  Setting up publishers and subscribers. Will also set up joint names as global variables.
    if rosInterfacePresent then
        robotObjectList = simGetObjectsInTree(robotHandle)
        revJointList = {robotObjectList[2],robotObjectList[3],robotObjectList[4]}
        eeHandle = robotObjectList[5]
        revJointName = {}
        for i=1,#revJointList,1
        do
            revJointName[i] = simGetObjectName(revJointList[i]);
        end
        simAuxiliaryConsolePrint(consoleHandle, simGetObjectName(eeHandle)..'\n')
        -- leg1 = simGetObjectsInTree(joint) --Get all object in tree under R2_B



        jointpub = simExtRosInterface_advertise('/Delta_base/rev_joint','sensor_msgs/JointState')
        eePospub = simExtRosInterface_advertise('/Delta_base/ee_pos','geometry_msgs/Pose')
        timepub = simExtRosInterface_advertise('/simulationTime','std_msgs/Float32')
        jointsub = simExtRosInterface_subscribe('/Delta_base/desired_joint_pos','sensor_msgs/JointState', 'jointsub_callback')
        velsub = simExtRosInterface_subscribe('/Delta_base/joint_vel','sensor_msgs/JointState', 'jointvel_callback')
    end
end

if (sim_call_type==sim_childscriptcall_actuation) then
    -- Publishing out ROS topics
    if rosInterfacePresent then
        local jointInfo = getHeader()
        jointInfo["name"] = revJointName
        jointInfo["position"] = getJointPositions() -- Joint angles are in radians.
        -- jointInfo["velocity"] = simGetObjectName(joint)
        -- jointInfo["effort"] = simGetObjectName(joint)
        simExtRosInterface_publish(timepub, {data = simGetSimulationTime()})
        simExtRosInterface_publish(jointpub, jointInfo)
        simExtRosInterface_publish(eePospub, getEEPose())
    end

end


if (sim_call_type==sim_childscriptcall_sensing) then

    -- Put your main SENSING code here

end


if (sim_call_type==sim_childscriptcall_cleanup) then
    if rosIntefacePresent then
        simExtRosInterface_shutdownPublisher(jointpub)
        simExtRosInterface_shutdownPublisher(timepubpub)
    end

end














