
clc;
robotarm = loadrobot("kinovaGen3");
removeBody(robotarm,'EndEffector_Link');
global X;
global Y;
realtime_mouth_detection;
x_scale=0.4/640;
z_scale=0.2/360;
% mouth place
origin_point=[0.3 0 0.3];
x=X*x_scale+origin_point(1);
z=Y*z_scale+origin_point(3);
x=double(x);
z=double(z);
%%
body = getBody(robotarm,'Shoulder_Link');
newJoint = rigidBodyJoint('limitjoint','revolute');
newJoint.PositionLimits=[0,0.5*pi];
 tform=trvec2tform([0, 0, 0.16])*eul2tform([0, 0, pi]);
 setFixedTransform(newJoint, tform); 
replaceJoint(robotarm,'Shoulder_Link',newJoint);
%%
 body6 = rigidBody('tool');
joint6 = rigidBodyJoint('fix1','revolute');
 joint6.PositionLimits=[-pi/100,pi/100];
 tform1=trvec2tform([0, 0, -0.1])*eul2tform([0, 0, 0]);
 setFixedTransform(joint6, tform1); 
 body6.Joint = joint6;
 addBody(robotarm, body6, 'Bracelet_Link');
 %%
body7= rigidBody('foodFrame');
setFixedTransform(body7.Joint, trvec2tform([0.5, -0.4, 0.3]));
addBody(robotarm,body7,'base_link');
robotarm.DataFormat='row';
body8= rigidBody('mouthFrame');
setFixedTransform(body8.Joint, trvec2tform([x, 0.4, z]));
addBody(robotarm,body8,'base_link');
%%
numWaypoints = 5;
q0 =homeConfiguration(robotarm);
qWaypoints = repmat(q0, numWaypoints, 1);
gik = generalizedInverseKinematics('RigidBodyTree', robotarm, ...
    'ConstraintInputs', {'cartesian','position','aiming','orientation','joint'});
heightAboveTable = constraintCartesianBounds('tool');
heightAboveTable.Bounds = [0, inf; ...
                           -inf, 0.4; ...
                           0.2, inf];
alignWithCup = constraintAiming('tool');
alignWithCup.TargetPoint = [-100, 0,100];

distanceFromCup = constraintPositionTarget('foodFrame');
distanceFromCup.ReferenceBody = 'tool';

distanceFromCup.PositionTolerance = 0.005;
limitJointChange = constraintJointBounds(robotarm);

fixOrientation = constraintOrientationTarget('Bracelet_Link');
fixOrientation.OrientationTolerance = deg2rad(0);

intermediateDistance = -0.3;
limitJointChange.Weights = zeros(size(limitJointChange.Weights));
fixOrientation.Weights = 0;

distanceFromCup.TargetPosition = [0,0,intermediateDistance];

[qWaypoints(2,:),solutionInfo] = gik(q0, heightAboveTable, ...
                       distanceFromCup, alignWithCup, fixOrientation, ...
                       limitJointChange);
limitJointChange.Weights = ones(size(limitJointChange.Weights));
fixOrientation.Weights = 1;
alignWithCup.Weights = 0;

fixOrientation.TargetOrientation = ...
tform2quat(getTransform(robotarm,qWaypoints(2,:),'tool'));
finalDistanceFromCup = -0.01;
distanceFromCupValues = linspace(intermediateDistance, finalDistanceFromCup, numWaypoints-1);
maxJointChange = deg2rad(15);

for k = 3:numWaypoints
    % Update the target position.
    distanceFromCup.TargetPosition(3) = distanceFromCupValues(k-1);
    % Restrict the joint positions to lie close to their previous values.
    q=qWaypoints(k-1,:)';
   
    limitJointChange.Bounds = [q-maxJointChange, q+maxJointChange];
                             
    % Solve for a configuration and add it to the waypoints array.
    [qWaypoints(k,:),solutionInfo] = gik(qWaypoints(k-1,:), ...
                                         heightAboveTable, ...
                                         distanceFromCup, alignWithCup, ...
                                         fixOrientation, limitJointChange);
end

framerate = 15;
r = rateControl(framerate);
tFinal = 10;
tWaypoints = [0,linspace(tFinal/2,tFinal,size(qWaypoints,1)-1)];
numFrames = tFinal*framerate;
qInterp = pchip(tWaypoints,qWaypoints',linspace(0,tFinal,numFrames))';

gripperPosition = zeros(numFrames,3);
for k = 1:numFrames
    gripperPosition(k,:) = tform2trvec(getTransform(robotarm,qInterp(k,:), ...
                                                    'tool'));
end

show(robotarm, qWaypoints(1,:), 'PreservePlot', false);
hold on
p = plot3(gripperPosition(1,1), gripperPosition(1,2), gripperPosition(1,3));

hold on
for k = 1:size(qInterp,1)
    show(robotarm, qInterp(k,:), 'PreservePlot', false);
    p.XData(k) = gripperPosition(k,1);
    p.YData(k) = gripperPosition(k,2);
    p.ZData(k) = gripperPosition(k,3);
    x1=[0.3 0.7 0.7 0.3 0.3];
    y1=[0.4 0.4 0.4 0.4 0.4];
    z1=[0.3 0.3 0.5 0.5 0.3];
    plot3(x1,y1,z1);
    xlim([-0.25 1.5]);
    xlabel('x-dir');
    ylim([-1 0.6]);
    ylabel('y-dir');
    zlim([0 1.2]);
    zlabel('z-dir');
    view([0 0.1 0.05]);
    waitfor(r);
end
%%
numWaypoints = 5;
q0 =qWaypoints(5,:);
qWaypoints = repmat(q0, numWaypoints, 1);
gik = generalizedInverseKinematics('RigidBodyTree', robotarm, ...
    'ConstraintInputs', {'cartesian','position','aiming','orientation','joint'});
heightAboveTable = constraintCartesianBounds('tool');
heightAboveTable.Bounds = [0, inf; ...
                           -inf, 0.4; ...
                           0.2, inf];
alignWithCup = constraintAiming('tool');
alignWithCup.TargetPoint = [0, -100,0];

distanceFromCup = constraintPositionTarget('mouthFrame');
distanceFromCup.ReferenceBody = 'tool';

distanceFromCup.PositionTolerance = 0.005;
limitJointChange = constraintJointBounds(robotarm);

fixOrientation = constraintOrientationTarget('Bracelet_Link');
fixOrientation.OrientationTolerance = deg2rad(1);

intermediateDistance = -0.3;
limitJointChange.Weights = zeros(size(limitJointChange.Weights));
fixOrientation.Weights = 0;

distanceFromCup.TargetPosition = [0,0,intermediateDistance];

[qWaypoints(2,:),solutionInfo] = gik(q0, heightAboveTable, ...
                       distanceFromCup, alignWithCup, fixOrientation, ...
                       limitJointChange);
limitJointChange.Weights = ones(size(limitJointChange.Weights));
fixOrientation.Weights = 1;
alignWithCup.Weights = 0;

fixOrientation.TargetOrientation = ...
tform2quat(getTransform(robotarm,qWaypoints(2,:),'tool'));
finalDistanceFromCup = 0.05;
distanceFromCupValues = linspace(intermediateDistance, finalDistanceFromCup, numWaypoints-1);
maxJointChange = deg2rad(20);

for k = 3:numWaypoints
    % Update the target position.
    distanceFromCup.TargetPosition(3) = distanceFromCupValues(k-1);
    % Restrict the joint positions to lie close to their previous values.
    q=qWaypoints(k-1,:)';
   
    limitJointChange.Bounds = [q-maxJointChange, q+maxJointChange];
                             
    % Solve for a configuration and add it to the waypoints array.
    [qWaypoints(k,:),solutionInfo] = gik(qWaypoints(k-1,:), ...
                                         heightAboveTable, ...
                                         distanceFromCup, alignWithCup, ...
                                         fixOrientation, limitJointChange);
end

framerate = 15;
r = rateControl(framerate);
tFinal = 10;
tWaypoints = [0,linspace(tFinal/2,tFinal,size(qWaypoints,1)-1)];
numFrames = tFinal*framerate;
qInterp = pchip(tWaypoints,qWaypoints',linspace(0,tFinal,numFrames))';

gripperPosition = zeros(numFrames,3);
for k = 1:numFrames
    gripperPosition(k,:) = tform2trvec(getTransform(robotarm,qInterp(k,:), ...
                                                    'tool'));
end
show(robotarm, qWaypoints(1,:), 'PreservePlot', false);
hold on
p = plot3(gripperPosition(1,1), gripperPosition(1,2), gripperPosition(1,3));

hold on
for k = 1:size(qInterp,1)
    show(robotarm, qInterp(k,:), 'PreservePlot', false);
    p.XData(k) = gripperPosition(k,1);
    p.YData(k) = gripperPosition(k,2);
    p.ZData(k) = gripperPosition(k,3);
    x1=[0.3 0.7 0.7 0.3 0.3];
    y1=[0.4 0.4 0.4 0.4 0.4];
    z1=[0.3 0.3 0.5 0.5 0.3];
    plot3(x1,y1,z1);
    xlim([-0.25 1.5]);
    xlabel('x-dir');
    ylim([-1 0.6]);
    ylabel('y-dir');
    zlim([0 1.2]);
    zlabel('z-dir');
    view([0 0.1 0.05]);
    waitfor(r);
end
hold off