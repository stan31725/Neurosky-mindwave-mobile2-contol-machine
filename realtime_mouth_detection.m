global X;
global Y;
clear cam;
cam=webcam();
cam.Resolution='640x360';
vedio_Frame=snapshot(cam);

% first two value are left and bottom corner the second two are height and
% width
vedio_Player=vision.VideoPlayer('Position',[1210 150  640 360]);

face_Detector=vision.CascadeObjectDetector('Mouth','MergeThreshold', 200);
point_Tracker=vision.PointTracker('MaxBidirectionalError',2);

run_loop=true;
number_of_Points=0;
frame_Count=0;

while run_loop &&frame_Count<150
    
    video_Frame=snapshot(cam);
    gray_Frame=rgb2gray(video_Frame);
    frame_Count=frame_Count+1;
    
    if number_of_Points<10
        face_Rectangle=face_Detector.step(gray_Frame);
        
        if ~isempty(face_Rectangle)
            points=detectMinEigenFeatures(gray_Frame, 'ROI', face_Rectangle(1, :));
            
            xy_Points=points.Location;
            number_of_Points=size(xy_Points, 1);
            release(point_Tracker);
            initialize(point_Tracker, xy_Points, gray_Frame);
            
            previous_Points=xy_Points;
            rectangle=bbox2points(face_Rectangle(1,:));
            face_Polygon=reshape(rectangle', 1, []);
            video_Frame=insertShape(video_Frame, 'Polygon', face_Polygon,'LineWidth', 3);
%             video_Frame=insertMarker(video_Frame, xy_Points, 'color', 'white');
        end
    else
        [xy_Points, isFound]=step(point_Tracker, gray_Frame);
        new_Points=xy_Points(isFound,:);
        old_Points=previous_Points(isFound,:);
        number_of_Points=size(new_Points,1);
        
        if number_of_Points >= 10
            [xform, old_Points, new_Points]=estimateGeometricTransform(...
            old_Points, new_Points, 'similarity', 'MaxDistance',4);
            rectangle=transformPointsForward(xform, rectangle);
            face_Polygon=reshape(rectangle',1,[]);
            video_Frame=insertShape(video_Frame, 'Polygon', face_Polygon,'LineWidth', 3);
%             video_Frame=insertMarker(video_Frame,xy_Points, 'color', 'white');
            
            previous_Points=new_Points;
            setPoints(point_Tracker, previous_Points);
        end
    end
    
    step(vedio_Player, video_Frame);
    run_loop=isOpen(vedio_Player);
    
   
end
      
  X=(rectangle(1,1)+rectangle(2,1)+rectangle(3,1)+rectangle(4,1))/4;
  Y=360-(rectangle(1,2)+rectangle(2,2)+rectangle(3,2)+rectangle(4,2))/4;
clear cam
release(vedio_Player);
release(point_Tracker);
release(face_Detector);
 

