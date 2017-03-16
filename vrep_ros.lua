-- DO NOT WRITE CODE OUTSIDE OF THE if-then-end SECTIONS BELOW!! (unless the code is a function definition)

if (sim_call_type==sim_childscriptcall_initialization) then
    -- Child Script Initialization
    objectHandle = simGetObjectAssociatedWithScript(sim_handle_self)
    objectName = simGetObjectName(objectHandle)

    --Check if required RosInterface is there:
    moduleName = 0
    index = 0
    rosInterfacePresent = false
    while moduleName do
        moduleName = simGetModuleName(index)
        if(moduleName = 'RosInterface') then
            rosInterfacePresent = true
        end
        index = index+1
    end

    --  Setting up publishers and subscribers. Will also set up joint names as global variables.
    if rosIntefacePresent
        joint = simGetObjectHandle('R2_B')
        jointpub = simExtRosInterface_advertise('/rev_joint','sensor_msgs/JointState')
        timepub = simExtRosInterface_advertise('/simulationTime','std_msgs/Float32')
    end
end

if (sim_call_type==sim_childscriptcall_actuation) then
    -- Publishing out ROS topics
    if rosInterfacePresent then

        simExtRosInterface_publish(timepub, {data = simGetSimulationTime()})
        simExtRosInterface_publish(jointpub, )
    end

end


if (sim_call_type==sim_childscriptcall_sensing) then

    -- Put your main SENSING code here

end


if (sim_call_type==sim_childscriptcall_cleanup) then

    -- Put some restoration code here

end
