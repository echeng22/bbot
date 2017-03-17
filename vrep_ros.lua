function getHeader()
    return {header = {stamp=simGetSystemTime()}}
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
        revJointList = simGetObjectsInTree(robotHandle)

        -- leg1 = simGetObjectsInTree(joint) --Get all object in tree under R2_B



        jointpub = simExtRosInterface_advertise('/rev_joint','sensor_msgs/JointState')
        timepub = simExtRosInterface_advertise('/simulationTime','std_msgs/Float32')
    end
end

if (sim_call_type==sim_childscriptcall_actuation) then
    -- Publishing out ROS topics
    if rosInterfacePresent then
        -- local jointInfo = getHeader()
        -- jointInfo["name"] = {simGetObjectName(joint)}
        -- jointInfo["position"] = {simGetJointPosition(joint)} -- Joint angles are in radians.
        -- -- jointInfo["velocity"] = simGetObjectName(joint)
        -- -- jointInfo["effort"] = simGetObjectName(joint)
        -- simExtRosInterface_publish(timepub, {data = simGetSimulationTime()})
        -- simExtRosInterface_publish(jointpub, jointInfo)
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














