function deg2rad(deg)
   return deg*math.pi/180
end

function rad2deg(rad)
   return rad*180/math.pi
end

function nullFunc(arg)
   return arg
end

function toggleRadians(ui,id,newVal)
   if (newVal==2) then
      angleTo = deg2rad
      angleFrom = rad2deg
   else
      angleTo = nullFunc
      angleFrom = nullFunc
   end
end

applyJoints=function(jointHandles,joints)
    for i=1,#jointHandles,1 do
        simSetJointPosition(jointHandles[i],joints[i])
    end
end

getJoints=function(jointHandles,angles)
   angles={0,0,0,0,0,0}
   for i=1,#jointHandles,1 do
      angles[i]=simGetJointPosition(jointHandles[i])
   end
   return angles
end

updateActualText=function(angles)
   local ang_str="( "
   for i=1,6,1 do
      -- simExtCustomUI_setLabelText(ui,4999+i,string.format('Actual = %+6.3f', angles[i]))
      ang_str=ang_str..string.format("%6.3f, ", angles[i])
   end
   ang_str=string.sub(ang_str,1,-3)
   ang_str=ang_str.."  )"
   simExtCustomUI_setLabelText(ui,1237,ang_str)
end

function changeAllSliders(ui,q)
   for i=1,6,1 do
      simExtCustomUI_setSliderValue(ui,3999+i,q[i]*1000)
      simExtCustomUI_setLabelText(ui,2999+i,string.format('Reference = %+6.3f',q[i]))
   end
end

function sliderChange(ui,id,newVal)
   for i=1,6,1 do
      if (id==3999+i) then
         simExtCustomUI_setLabelText(ui,2999+i,string.format('Reference = %+6.3f',newVal/1000))
         ref_ang[i]=newVal/1000
         break
      end
   end
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

function fulljointEntry(ui,id,newVal)
   if (newVal==enteredString) then
      enteredString=newVal
      out=string.format("Already processed and sent this string... try editing")
      simExtCustomUI_setLabelText(ui, 1236, out)
      return
   end
   enteredString=newVal
   local q=mysplit(newVal,",")
   local out=""
   if (#q==0) then
      out=string.format("No conversions completed <br> Are you separating with commas?")
      simExtCustomUI_setLabelText(ui, 1236, out)
      return
   elseif (#q<#jh) then
      out=string.format("Not enough configuration variables specified")
      simExtCustomUI_setLabelText(ui, 1236, out)
      return
   elseif (#q>#jh) then
      out=string.format("Too many configuration variables specified")
      simExtCustomUI_setLabelText(ui, 1236, out)
      return
   end
   for i=1,#q,1 do
      qtest=tonumber(q[i])
      if (qtest==nil) then
         out=string.format("Could not convert entry number %d:<br> Entered='",i,q[i])..q[i].."'"
         simExtCustomUI_setLabelText(ui, 1236, out)
         return
      else
         q[i]=qtest
      end
   end
   simExtCustomUI_setLabelText(ui, 1236, "Successful conversion:<br>"..newVal)
   changeAllSliders(ui, q)
   ref_ang = q
end


function jointEntry(ui,id,newVal)
   angle = tonumber(newVal)
   if (angle==nil) then
      print("Could not convert number..."..newVal)
      return
   end
   if (angle >= 2*math.pi) then
      print("Clipping angle to 2pi")
      angle = 2*math.pi
   end
   if (angle <= -2*math.pi) then
      print("Clipping angle to -2pi")
      angle = -2*math.pi
   end
   for i=1,6,1 do
      if (id==6999+i) then
         simExtCustomUI_setLabelText(ui,2999+i,string.format('Reference = %+6.3f',angle))
         ref_ang[i]=angle
         break
      end
   end
end


function eul2so3_xyzr(a,b,c)
   -- Build empty array
   R = {}
   for i=1,3,1 do
      R[i] = {}
      for j=1,3,1 do
         R[i][j] = 0
      end
   end

   -- calculate constants
   local c1,s1 = math.cos(a),math.sin(a)
   local c2,s2 = math.cos(b),math.sin(b)
   local c3,s3 = math.cos(c),math.sin(c)

   -- fill out values:
   -- https://en.wikipedia.org/wiki/Euler_angles#Rotation_matrix
   R[1][1] = c2*c3
   R[1][2] = -c2*s3
   R[1][3] = s2
   R[2][1] = c1*s3+c3*s1*s2
   R[2][2] = c1*c3-s1*s2*s3
   R[2][3] = -c2*s1
   R[3][1] = s1*s3-c1*c3*s2
   R[3][2] = c3*s1+c1*s2*s3
   R[3][3] = c1*c2
   return R
end

function so3andp2se3(R,p)
   local g = {}
   for i=1,4,1 do
      g[i] = {}
      for j=1,4,1 do
         if (i<=3) then
            if (j<=3) then
               g[i][j] = R[i][j]
            else
               g[i][j] = p[i]
            end
         else
            if (j<=3) then
               g[i][j] = 0
            else
               g[i][j] = 1
            end
         end
      end
   end
   return g
end

function createSE3string(pos,ori)
   -- first let's convert the orientation into an SE(3) matrix:
   local R=eul2so3_xyzr(ori[1], ori[2], ori[3])
   local g=so3andp2se3(R,pos)
   local out="<b><big><tt>"
   for i=1,4,1 do
      out=out.."| "
      for j=1,4,1 do
         out=out..string.format(" %+6.3f",g[i][j])
      end
      out=out.." | <br>"
   end
   out=out.."</tt></big></b>"
   return out
end

function calcSE3(ui, id)
   pos=simGetObjectPosition(ee,base)
   ori=simGetObjectOrientation(ee,base)
   if pos and ori then
      out=createSE3string(pos,ori)
      simExtCustomUI_setLabelText(ui,1234,out)
   end
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

   xml = [[
   <ui closeable="false" onclose="closeEventHandler" resizable="true">
     <tabs>

       <tab title="Enter Config and SE(3) Value">
         <group>
           <group layout="vbox">
             <label text="<big> Configuration Entry:</big>" wordwrap="false" style="font-weight: bold;"/>
             <label text="Enter 6 comma-separated angles" />
             <edit value="" id="7006" oneditingfinished="fulljointEntry" />
             <label value="" id="5006" wordwrap="false" />
             <label text="<big> Current configuration:</big>" id="6007" wordwrap="false" style="font-weight: bold;"/>
             <group layout="vbox">
               <label value="" id="1237" wordwrap="true" />
             </group>
             <label text="<big> Messages:</big>" id="6006" wordwrap="false" style="font-weight: bold;"/>
             <group layout="vbox">
               <label value="" id="1236" wordwrap="true" />
             </group>
           </group>
           <group>
             <!-- <group> -->
               <label text="<big> Current SE(3):</big>" id="6008" wordwrap="false" style="font-weight: bold;"/>
               <!-- <button text="Calculate SE(3) transform:" onclick="calcSE3" id="1235"/> -->
               <label text="T(Î¸) = " wordwrap="false" />
               <label text="" id="1234" wordwrap="false" />
             <!-- </group> -->
              <!-- <group> -->
              <!--   <label text="<big> Settings:</big>" wordwrap="false" style="font-weight: bold;"/> -->
              <!--   <checkbox text="Use degrees instead of radians?" checked="false" onchange="toggleRadians" /> -->
              <!-- </group> -->
           </group>
           <stretch />
         </group>
       </tab>


       <tab title="Joint Angle Sliders">
         <group layout="grid" >
           <group>
             <group layout="grid">
               <label text="<big> Joint 1:</big>" id="6000" wordwrap="false" style="font-weight: bold;"/>
               <label text="Reference =  0.000" id="3000" wordwrap="false" />
               <!-- <label text="Actual =  0.000" id="5000" wordwrap="false" /> -->
             </group>
             <hslider id="4000" tick-position="above" tick-interval="1000" minimum="-6280" maximum="6280" onchange="sliderChange" />
             <group layout="grid">
               <label text="Enter angle:" />
               <edit value="" id="7000" oneditingfinished="jointEntry" />
             </group>
           </group>

           <group>
             <group layout="grid">
               <label text="<big> Joint 4:</big>" id="6003" wordwrap="false" style="font-weight: bold;"/>
               <label text="Reference =  0.000" id="3003" wordwrap="false" />
               <!-- <label text="Actual =  0.000" id="5003" wordwrap="false" /> -->
             </group>
             <hslider id="4003" tick-position="above" tick-interval="1000" minimum="-6280" maximum="6280" onchange="sliderChange" />
             <group layout="grid">
               <label text="Enter angle:" />
               <edit value="" id="7003" oneditingfinished="jointEntry" />
             </group>
           </group>

           <br/>

           <group>
             <group layout="grid">
               <label text="<big> Joint 2:</big>" id="6001" wordwrap="false" style="font-weight: bold;"/>
               <label text="Reference =  0.000" id="3001" wordwrap="false" />
               <!-- <label text="Actual =  0.000" id="5001" wordwrap="false" /> -->
             </group>
             <hslider id="4001" tick-position="above" tick-interval="1000" minimum="-6280" maximum="6280" onchange="sliderChange" />
             <group layout="grid">
               <label text="Enter angle:" />
               <edit value="" id="7001" oneditingfinished="jointEntry" />
             </group>
           </group>


           <group>
             <group layout="grid">
               <label text="<big> Joint 5:</big>" id="6004" wordwrap="false" style="font-weight: bold;"/>
               <label text="Reference =  0.000" id="3004" wordwrap="false" />
               <!-- <label text="Actual =  0.000" id="5004" wordwrap="false" /> -->
             </group>
             <hslider id="4004" tick-position="above" tick-interval="1000" minimum="-6280" maximum="6280" onchange="sliderChange" />
             <group layout="grid">
               <label text="Enter angle:" />
               <edit value="" id="7004" oneditingfinished="jointEntry" />
             </group>
           </group>

           <br/>

           <group>
             <group layout="grid">
               <label text="<big> Joint 3:</big>" id="6002" wordwrap="false" style="font-weight: bold;"/>
               <label text="Reference =  0.000" id="3002" wordwrap="false" />
               <!-- <label text="Actual =  0.000" id="5002" wordwrap="false" /> -->
             </group>
             <hslider id="4002" tick-position="above" tick-interval="1000" minimum="-6280" maximum="6280" onchange="sliderChange" />
             <group layout="grid">
               <label text="Enter angle:" />
               <edit value="" id="7002" oneditingfinished="jointEntry" />
             </group>
           </group>

           <group>
             <group layout="grid">
               <label text="<big> Joint 6:</big>" id="6005" wordwrap="false" style="font-weight: bold;"/>
               <label text="Reference =  0.000" id="3005" wordwrap="false" />
               <!-- <label text="Actual =  0.000" id="5005" wordwrap="false" /> -->
             </group>
             <hslider id="4005" tick-position="above" tick-interval="1000" minimum="-6280" maximum="6280" onchange="sliderChange" />
             <group layout="grid">
               <label text="Enter angle:" />
               <edit value="" id="7005" oneditingfinished="jointEntry" />
             </group>
           </group>
         </group>
       </tab>

    </tabs>
</ui>
]]
    ui=simExtCustomUI_create(xml)
    -- get joints:
    jh={-1,-1,-1,-1,-1,-1}
    for i=1,6,1 do
        jh[i]=simGetObjectHandle('UR5_joint'..i)
    end
    -- base=simGetObjectHandle('UR5_link1_visible')
    -- ee=simGetObjectHandle('UR5_connection')
    base=simGetObjectHandle('Base_Frame')
    ee=simGetObjectHandle('EE_Frame')
    -- fill out initial string:
    calcSE3(ui, 1235)
    -- array for reference angle
    ref_ang={0,0,0,0,0,0}
    -- array for storing when angles where manually entered
    enteredString=""
    -- angle parsing
    toggleRadians(ui,0,0)
end


if (sim_call_type==sim_childscriptcall_actuation) then
   applyJoints(jh, ref_ang)
   -- array for actual angle
   act_ang = getJoints(jh)
   updateActualText(act_ang)
   calcSE3(ui, 1235)
end

if (sim_call_type==sim_childscriptcall_sensing) then

end

if (sim_call_type==sim_childscriptcall_cleanup) then
    simExtCustomUI_destroy(ui)
end
