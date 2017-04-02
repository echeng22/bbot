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

------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- Functions responsible for starting/stopping ROS Communication
------------------------------------------------------------------------------------------------------------------

function startROS(u, id)
    ROSCom = true
end

function stopROS(u, id)
    ROSCom = false
end

------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- Functions responsible for loading delta robot model into scene
------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------

function closeEventHandler(h)
   simAddStatusbarMessage('Window '..h..' is closing...')
   simExtCustomUI_hide(h)
end

if (sim_call_type==sim_childscriptcall_initialization) then

   xml = [[<ui closeable="true" onclose="closeEventHandler" resizable="true">
     <tabs>
       <tab title="Create Delta Robot">

         <group layout="vbox">
           <group layout="hbox">
             <button text="Clear Scene" onclick="clearScene" id="2000" />
             <button text="Load Model" onclick="loadDelta" id="2001" />
             <button text="Start ROS Sim" onclick="startROS" id="2002" />
             <button text="Stop ROS Sim" onclick="stopROS" id="2003" />
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
   ROSCom = false
end

if (sim_call_type==sim_childscriptcall_actuation) then

    -- Put your main ACTUATION code here

    -- For example:
    --
    -- local position=simGetObjectPosition(handle,-1)
    -- position[1]=position[1]+0.001
    -- simSetObjectPosition(handle,-1,position)

end


if (sim_call_type==sim_childscriptcall_sensing) then

    -- Put your main SENSING code here

end


if (sim_call_type==sim_childscriptcall_cleanup) then

    -- Put some restoration code here

end
