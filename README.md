## What's in this Repo
In the Simulations folder, you will see 3 main folders that make up the V-REP scenes for the winter project.

#### Lua Folder
Contains lua scripts that can be run on V-REP. These scripts are also contained inside the V-REP scense themselves. These scripts are seperated out for editing convenience, as well as backups, due to scripts not auto-saving in V-REP.

#### Models Folder
Contains previous and current models used for this winter project.

####Scenes Folder
Contains previous and current scenes used for this winter project. The main scene files to use are:

    - delta_robot_ROS_v1: Scene of a dynamic delta robot that is set-up for communication with ROS.

    - delta_robot_RUU_ik_v1: Scene of a delta robot that can find an inverse kinematics solution of the delta robot. Due to the nature of the model, confirming the accuracy of the solutions is difficult. Improvements are being made to make this easier to check.

    - delta_robot_RUU_scaling_v1: Proof of concept scene to see if scaling is possible for the modeling of the delta robot.

    - delta_robot_RUU_v1: Scene of a dynamic delta robot. This is NOT set up for ROS communication, and is the first version to see a working model of the dynamics of the delta robot.
