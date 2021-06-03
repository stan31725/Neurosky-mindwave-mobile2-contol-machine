function readeyeblink
%Clear Screen
clear
%Clear Variables
clc
%Close figures
%% 
% store time aomng the eyeblink  
fout1 = fopen('eyeblink_test','w');

fprintf(fout1,'time\n');
fout2 = fopen('eyeblink_test1','w');

fprintf(fout2,'time\n');
%%
%Preallocate buffer
data_blink = zeros(1,256);
%Comport Selection
portnum1 = 3;
%COM Port #
comPortName1 = sprintf('\\\\.\\COM%d', portnum1);
% Baud rate for use with TG_Connect() and TG_SetBaudrate().
TG_BAUD_115200 = 115200;
% Data format for use with TG_Connect() and TG_SetDataFormat().
TG_STREAM_PACKETS = 0;
% Data type that can be requested from TG_GetValue().
TG_DATA_BLINK_STRENGTH = 37;
%load thinkgear dll
loadlibrary('thinkgear64.dll','thinkgear64.h');
%To display in Command Window

% fprintf('thinkgear64.dll loaded\n');

%get dll version
dllVersion = calllib('thinkgear64', 'TG_GetDriverVersion');
%To display in command window

% fprintf('ThinkGear DLL version: %d\n', dllVersion 
global time2;
% Get a connection ID handle to ThinkGear
connectionId1 = calllib('thinkgear64', 'TG_GetNewConnectionId');
if ( connectionId1 < 0 )
    error( sprintf( 'ERROR: TG_GetNewConnectionId() returned %d.\n', connectionId1 ) );
end;
% Attempt to connect the connection ID handle to serial port "COM3"
errCode = calllib('thinkgear64', 'TG_Connect', connectionId1,comPortName1,TG_BAUD_115200,TG_STREAM_PACKETS );
if ( errCode < 0 )
error( sprintf( 'ERROR: TG_Connect() returned %d.\n', errCode ) );
end

% fprintf( 'Connected. Reading Packets...\n' );

if(calllib('thinkgear64','TG_EnableBlinkDetection',connectionId1,1)==0)
    
% disp('blinkdetectenabled');

end
i=0;
j=0;
%To display in Command Window
disp('Reading Brainwaves');
while 1
  tic
while 1
  j = j + 1;
i = i + 1;  
   
if (calllib('thinkgear64','TG_ReadPackets',connectionId1,1) == 1) %if a packet was read...
if (calllib('thinkgear64','TG_GetValueStatus',connectionId1,TG_DATA_BLINK_STRENGTH) ~= 0)

%Read attention Valus from thinkgear packets

data_blink(j) = calllib('thinkgear64','TG_GetValue',connectionId1,TG_DATA_BLINK_STRENGTH );

time1=toc

    disp(data_blink(j));
    X(i)=data_blink(j);
    
fprintf(fout1,'%6.5f\n',time1);
        

 if X(i)>0
    
    break
end
end
end

end

if time1<0.5
    
    break
end
end
fclose(fout1);

i=0;
j=0;
data_blink1 = zeros(1,256);
while i<2 
  tic
while i<2 
if (calllib('thinkgear64','TG_ReadPackets',connectionId1,1) == 1) %if a packet was read...
if (calllib('thinkgear64','TG_GetValueStatus',connectionId1,TG_DATA_BLINK_STRENGTH) ~= 0)
j = j + 1;
i = i + 1;
%Read attention Valus from thinkgear packets
data_blink1(j) = calllib('thinkgear64','TG_GetValue',connectionId1,TG_DATA_BLINK_STRENGTH );
 time2=toc
    disp(data_blink1(j));
    X(i)=data_blink1(j);  
fprintf(fout2,'%6.5f\n',time2);
if time2>0
    break
end
end
end
end
end

fclose(fout2);


%To display in Command Window

% disp('Loop Completed')

%Release the comm port
calllib('thinkgear64', 'TG_FreeConnection', connectionId1 );
end
