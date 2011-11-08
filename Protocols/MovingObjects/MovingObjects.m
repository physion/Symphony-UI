classdef MovingObjects < StimGLProtocol

    properties (Constant)
        identifier = 'org.janelia.research.murphy.stimgl.movingobjects'
        version = 1
        displayName = 'Moving Objects'
        plugInName = 'MovingObjects'
        xMonPix = 1280;
        yMonPix = 720;
        screenDist = 12.8;
        screenWidth = 22.4;
        screenHeight = 12.6;
        screenHeightBelow = 3.3;
    end
    
    properties (Hidden)
        trialTypes
        notCompletedTrialTypes
        plotData
    end

    properties
        spikePolThrLimRet = [Inf,1,100,1];
        preTime = 1;
        postTime = 2;
        intertrialIntervalMin = 1;
        intertrialIntervalMax = 2;
        backgroundColor = 0;
        objectColor = 1;
        objectSize = [5,20];
        RFcenterX = 400;
        RFcenterY = 300;
        Xoffset = 0;
        Yoffset = 0;
        objectSpeed = [10,30];
        objectDir = 0:45:315;
    end
    
    
    methods
        
        function prepareRun(obj)
            % Call the base class method which clears all figures.
            prepareRun@SymphonyProtocol(obj);
            
            obj.loopCount = 1;
            
            % Get all combinations of trial types based on object size, speed, and direction
            obj.trialTypes = allcombs(obj.objectSize,obj.objectSpeed,obj.objectDir);
            obj.notCompletedTrialTypes = 1:size(obj.trialTypes,1);
            
            % Prepare figures
            obj.openFigure('Custom','Name','ResponseFig','UpdateCallback',@updateResponseFig);
            if numel(obj.objectSpeed)>1
                obj.plotData.meanSpeedResp = NaN(1,numel(obj.objectSpeed));
                obj.openFigure('Custom','Name','MeanSpeedRespFig','UpdateCallback',@updateMeanSpeedRespFig);
            end
            if numel(obj.objectDir)>1
                obj.plotData.meanDirResp = NaN(1,numel(obj.objectDir));
                obj.openFigure('Custom','Name','MeanDirRespFig','UpdateCallback',@updateMeanDirRespFig);
            end
        end
        
        function updateResponseFig(obj,axesHandle)
            data=obj.response('Amplifier_Ch1');
            if obj.epochNum==1
                obj.plotData.responseLineHandle = line(obj.plotData.time,data,'Parent',axesHandle,'Color','k');
                obj.plotData.spikeMarkerHandle = line(obj.plotData.time(obj.plotData.spikePts),data(obj.plotData.spikePts),'Parent',axesHandle,'Color','g','Marker','o');
                obj.plotData.stimBeginLineHandle = line([0,0],get(axesHandle,'YLim'),'Color','k','LineStyle',':');
                obj.plotData.stimEndLineHandle = line([obj.plotData.stimTime,obj.plotData.stimTime],get(axesHandle,'YLim'),'Color','k','LineStyle',':');
                xlabel(axesHandle,'s');
                ylabel(axesHandle,'mV');
                set(axesHandle,'Box','off','TickDir','out','Position',[0.1 0.1 0.85 0.8]);
                obj.plotData.epochCountHandle = uicontrol(get(axesHandle,'Parent'),'Style','text','Units','normalized','Position',[0.25 0.96 0.5 0.03],'FontWeight','bold');
                uicontrol(get(axesHandle,'Parent'),'Style','text','Units','normalized','Position',[0.17 0.915 0.075 0.03],'String','polarity');
                obj.plotData.polarityEditHandle = uicontrol(get(axesHandle,'Parent'),'Style','edit','Units','normalized','Position',[0.255 0.905 0.075 0.05],'String',num2str(obj.spikePolThrLimRet(1)));
                uicontrol(get(axesHandle,'Parent'),'Style','text','Units','normalized','Position',[0.35 0.915 0.075 0.03],'String','thresh');
                obj.plotData.threshEditHandle = uicontrol(get(axesHandle,'Parent'),'Style','edit','Units','normalized','Position',[0.435 0.905 0.075 0.05],'String',num2str(obj.spikePolThrLimRet(2)));
                uicontrol(get(axesHandle,'Parent'),'Style','text','Units','normalized','Position',[0.53 0.915 0.075 0.03],'String','limit');
                obj.plotData.limitEditHandle = uicontrol(get(axesHandle,'Parent'),'Style','edit','Units','normalized','Position',[0.615 0.905 0.075 0.05],'String',num2str(obj.spikePolThrLimRet(3)));
                uicontrol(get(axesHandle,'Parent'),'Style','text','Units','normalized','Position',[0.71 0.915 0.075 0.03],'String','return');
                obj.plotData.returnEditHandle = uicontrol(get(axesHandle,'Parent'),'Style','edit','Units','normalized','Position',[0.795 0.905 0.075 0.05],'String',num2str(obj.spikePolThrLimRet(4)));
            else
                set(obj.plotData.responseLineHandle,'Xdata',obj.plotData.time,'Ydata',data);
                set(obj.plotData.spikeMarkerHandle,'Xdata',obj.plotData.time(obj.plotData.spikePts),'Ydata',data(obj.plotData.spikePts));
            end
            set(obj.plotData.stimEndLineHandle,'Xdata',[obj.plotData.stimTime,obj.plotData.stimTime]);
            set([obj.plotData.stimBeginLineHandle,obj.plotData.stimEndLineHandle],'Ydata',get(axesHandle,'YLim'));
            xlim(axesHandle,[-obj.preTime,max(obj.plotData.time)]);
            set(obj.plotData.epochCountHandle,'String',['Epoch ' num2str(obj.epochNum-size(obj.trialTypes,1)*(obj.loopCount-1)) ' of ' num2str(size(obj.trialTypes,1)) ' in loop ' num2str(obj.loopCount) ' of ' num2str(obj.numberOfLoops)]);
        end
        
        function updateMeanSpeedRespFig(obj,axesHandle)
            if obj.epochNum==1
                obj.plotData.meanSpeedRespHandle = line(obj.objectSpeed,obj.plotData.meanSpeedResp,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none','MarkerFaceColor','k');
                set(axesHandle,'Box','off','TickDir','out','XLim',[min(obj.objectSpeed)-1,max(obj.objectSpeed)+1],'Xtick',obj.objectSpeed);
                xlabel(axesHandle,'object speed (degrees/s)');
                ylabel(axesHandle,'response (spike count)');
            else
                set(obj.plotData.meanSpeedRespHandle,'Ydata',obj.plotData.meanSpeedResp);
            end
            line(obj.plotData.epochObjectSpeed,obj.plotData.epochResp,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none');
        end
        
        function updateMeanDirRespFig(obj,axesHandle)
            if obj.epochNum==1
                obj.plotData.meanDirRespHandle = line(obj.objectDir,obj.plotData.meanDirResp,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none','MarkerFaceColor','k');
                set(axesHandle,'Box','off','TickDir','out','XLim',[min(obj.objectDir)-10,max(obj.objectDir)+10],'Xtick',obj.objectDir);
                xlabel(axesHandle,'object direction (degrees relative to vertical)');
                ylabel(axesHandle,'response (spike count)');
            else
                set(obj.plotData.meanDirRespHandle,'Ydata',obj.plotData.meanDirResp);
            end
            line(obj.plotData.epochObjectDir,obj.plotData.epochResp,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none');
        end
        
        function prepareEpoch(obj)
            % Call the base class method which sets up default backgrounds and records responses.
            prepareEpoch@SymphonyProtocol(obj);
            
            % Set constant parameters
            params.x_mon_pix = obj.xMonPix;
            params.y_mon_pix = obj.yMonPix;
            params.bgcolor = obj.backgroundColor;
            params.interTrialBg = repmat(obj.backgroundColor,1,3);
            
            % Pick a combination of object size/speed/direction from the trialTypes list
            % complete all combinations before repeating any particular combination
            rng('shuffle');
            randIndex = randi(numel(obj.notCompletedTrialTypes),1);
            epochTrialType = obj.notCompletedTrialTypes(randIndex);
            obj.notCompletedTrialTypes(randIndex) = [];
            epochObjectSize = obj.trialTypes(epochTrialType,1);
            epochObjectSpeed = obj.trialTypes(epochTrialType,2);
            epochObjectDir = obj.trialTypes(epochTrialType,3);
            obj.plotData.epochObjectSpeed = epochObjectSpeed;
            obj.plotData.epochObjectDir = epochObjectDir;
            
            % Determine object path (get start and end postions in pixels)
            % (add offset so objects start and end just off the screen)
            screenDistPix = obj.screenDist*(obj.xMonPix/obj.screenWidth);
            screenHeightBelowPix = obj.screenHeightBelow*(obj.xMonPix/obj.screenWidth);
            XcenterDeg=obj.RFcenterX+obj.Xoffset;
            YcenterDeg=obj.RFcenterY+obj.Yoffset;
            XcenterPix = 0.5*obj.xMonPix+screenDistPix*tand(XcenterDeg);
            YcenterPix = screenHeightBelowPix+screenDistPix*tand(YcenterDeg);
            if epochObjectDir==0
                XstartPix = XcenterPix;
                YstartPix = 0;
                XendPix = XcenterPix;
                YendPix = obj.yMonPix;
                XstartOffsetDeg = 0;
                YstartOffsetDeg = -0.5*epochObjectSize;
                XendOffsetDeg = 0;
                YendOffsetDeg = 0.5*epochObjectSize;
            elseif epochObjectDir>0 && epochObjectDir<90
                m = tand(90-epochObjectDir);
                xintercept = XcenterPix-YcenterPix/m;
                yintercept = -m*xintercept;
                if xintercept<0
                    XstartPix = 0;
                    YstartPix = yintercept;
                    XstartOffsetDeg = -0.5*epochObjectSize;
                    YstartOffsetDeg = -0.5*epochObjectSize*m;
                else
                    XstartPix = xintercept;
                    YstartPix = 0;
                    XstartOffsetDeg = -0.5*epochObjectSize/m;
                    YstartOffsetDeg = -0.5*epochObjectSize;
                end
                XendPix = (obj.yMonPix-yintercept)/m;
                if XendPix>obj.xMonPix
                    XendPix=obj.xMonPix;
                    XendOffsetDeg = 0.5*epochObjectSize;
                else
                    XendOffsetDeg = 0.5*epochObjectSize/m;
                end
                YendPix = m*obj.xMonPix+yintercept;
                if YendPix>obj.yMonPix
                    YendPix=obj.yMonPix;
                    YendOffsetDeg = 0.5*epochObjectSize;
                else
                    YendOffsetDeg = 0.5*epochObjectSize*m;
                end
            elseif epochObjectDir==90
                XstartPix = 0;
                YstartPix = YcenterPix;
                XendPix = obj.xMonPix;
                YendPix = YcenterPix;
                XstartOffsetDeg = -0.5*epochObjectSize;
                YstartOffsetDeg = 0;
                XendOffsetDeg = 0.5*epochObjectSize;
                YendOffsetDeg = 0;
            elseif epochObjectDir>90 && epochObjectDir<180
                m = -tand(epochObjectDir-90);
                xintercept = XcenterPix-(obj.yMonPix-YcenterPix)/-m;
                yintercept = -m*xintercept;
                if xintercept<0
                    XstartPix = 0;
                    YstartPix = obj.yMonPix+yintercept;
                    XstartOffsetDeg = -0.5*epochObjectSize;
                    YstartOffsetDeg = 0.5*epochObjectSize*(-m);
                else
                    XstartPix = xintercept;
                    YstartPix = obj.yMonPix;
                    XstartOffsetDeg = -0.5*epochObjectSize/(-m);
                    YstartOffsetDeg = 0.5*epochObjectSize;
                end
                XendPix = (-obj.yMonPix-yintercept)/m;
                if XendPix>obj.xMonPix
                    XendPix=obj.xMonPix;
                    XendOffsetDeg = 0.5*epochObjectSize;
                else
                    XendOffsetDeg = 0.5*epochObjectSize/(-m);
                end
                YendPix = m*obj.xMonPix+yintercept;
                if YendPix<-obj.yMonPix
                    YendPix = 0;
                    YendOffsetDeg = -0.5*epochObjectSize;
                else
                    YendPix = obj.yMonPix+YendPix;
                    YendOffsetDeg = -0.5*epochObjectSize*(-m);
                end
            elseif epochObjectDir==180
                XstartPix = XcenterPix;
                YstartPix = obj.yMonPix;
                XendPix = XcenterPix;
                YendPix = 0;
                XstartOffsetDeg = 0;
                YstartOffsetDeg = 0.5*epochObjectSize;
                XendOffsetDeg = 0;
                YendOffsetDeg = -0.5*epochObjectSize;
            elseif epochObjectDir>180 && epochObjectDir<270
                m = tand(270-epochObjectDir);
                xintercept = -obj.xMonPix+XcenterPix+(obj.yMonPix-YcenterPix)/m;
                yintercept = -m*xintercept;
                if xintercept>0
                    XstartPix = obj.xMonPix;
                    YstartPix = obj.yMonPix+yintercept;
                    XstartOffsetDeg = 0.5*epochObjectSize;
                    YstartOffsetDeg = 0.5*epochObjectSize*m;
                else
                    XstartPix = obj.xMonPix+xintercept;
                    YstartPix = obj.yMonPix;
                    XstartOffsetDeg = 0.5*epochObjectSize/m;
                    YstartOffsetDeg = 0.5*epochObjectSize;
                end
                XendPix = (-obj.yMonPix-yintercept)/m;
                if XendPix<-obj.xMonPix
                    XendPix = 0;
                    XendOffsetDeg = -0.5*epochObjectSize;
                else
                    XendPix = obj.xMonPix+XendPix;
                    XendOffsetDeg = -0.5*epochObjectSize/m;
                end
                YendPix = m*-obj.xMonPix+yintercept;
                if YendPix<-obj.yMonPix
                    YendPix = 0;
                    YendOffsetDeg = -0.5*epochObjectSize;
                else
                    YendPix = obj.yMonPix+YendPix;
                    YendOffsetDeg = -0.5*epochObjectSize*m;
                end
            elseif epochObjectDir==270
                XstartPix = obj.xMonPix;
                YstartPix = YcenterPix;
                XendPix = 0;
                YendPix = YcenterPix;
                XstartOffsetDeg = 0.5*epochObjectSize;
                YstartOffsetDeg = 0;
                XendOffsetDeg = -0.5*epochObjectSize;
                YendOffsetDeg = 0;
            elseif epochObjectDir>270 && epochObjectDir<360
                m = -tand(epochObjectDir-270);
                xintercept = -obj.xMonPix+XcenterPix+YcenterPix/-m;
                yintercept = -m*xintercept;
                if xintercept>0
                    XstartPix = obj.xMonPix;
                    YstartPix = yintercept;
                    XstartOffsetDeg = 0.5*epochObjectSize;
                    YstartOffsetDeg = -0.5*epochObjectSize*(-m);
                else
                    XstartPix = obj.xMonPix+xintercept;
                    YstartPix = 0;
                    XstartOffsetDeg = 0.5*epochObjectSize/(-m);
                    YstartOffsetDeg = -0.5*epochObjectSize;
                end
                XendPix = (obj.yMonPix-yintercept)/m;
                if XendPix<-obj.xMonPix
                    XendPix = 0;
                    XendOffsetDeg = -0.5*epochObjectSize;
                else
                    XendPix = obj.xMonPix+XendPix;
                    XendOffsetDeg = -0.5*epochObjectSize/(-m);
                end
                YendPix = m*-obj.xMonPix+yintercept;
                if YendPix>obj.yMonPix
                    YendPix = obj.yMonPix;
                    YendOffsetDeg = 0.5*epochObjectSize;
                else
                    YendOffsetDeg = 0.5*epochObjectSize*(-m);
                end
            end
            
            % Determine number of frames to complete path and X and Y positions in degrees at each frame
            frameRate = double(GetRefreshRate(obj.stimGL));
            XstartDeg = atand((XstartPix-0.5*obj.xMonPix)/screenDistPix)+XstartOffsetDeg;
            XendDeg = atand((XendPix-0.5*obj.xMonPix)/screenDistPix)+XendOffsetDeg;
            YstartDeg = atand((YstartPix-screenHeightBelowPix)/screenDistPix)+YstartOffsetDeg;
            YendDeg = atand((YendPix-screenHeightBelowPix)/screenDistPix)+YendOffsetDeg;
            pathDistDeg = sqrt((XendDeg-XstartDeg)^2+(YendDeg-YstartDeg)^2);
            nStimFrames = round(pathDistDeg/epochObjectSpeed*frameRate)+1;
            if XendDeg==XstartDeg
                XposVectorDeg = XstartDeg*ones(1,nStimFrames);
            else
                XposVectorDeg = XstartDeg:(XendDeg-XstartDeg)/(nStimFrames-1):XendDeg;
            end
            if YendDeg==YstartDeg
                YposVectorDeg = YstartDeg*ones(1,nStimFrames);
            else
                YposVectorDeg = YstartDeg:(YendDeg-YstartDeg)/(nStimFrames-1):YendDeg;
            end
             
            % Determine object size and position at each frame in pixels
            % Pad object size vector with zeros to make object disappear
            % during postTime and while stop stimGL completes
            leftEdgesPix = 0.5*obj.xMonPix+screenDistPix*tand(XposVectorDeg-0.5*epochObjectSize);
            rightEdgesPix = 0.5*obj.xMonPix+screenDistPix*tand(XposVectorDeg+0.5*epochObjectSize);
            bottomEdgesPix = screenHeightBelowPix+screenDistPix*tand(YposVectorDeg-0.5*epochObjectSize);
            topEdgesPix = screenHeightBelowPix+screenDistPix*tand(YposVectorDeg+0.5*epochObjectSize);
            XsizeVectorPix = rightEdgesPix-leftEdgesPix;
            YsizeVectorPix = topEdgesPix-bottomEdgesPix;
            XposVectorPix = leftEdgesPix+0.5*XsizeVectorPix;
            YposVectorPix = bottomEdgesPix+0.5*YsizeVectorPix;
            XsizeVectorPix =[XsizeVectorPix,zeros(1,(obj.postTime+10)*frameRate)];
            YsizeVectorPix =[YsizeVectorPix,zeros(1,(obj.postTime+10)*frameRate)];
            
            % Specify frame parameters in frame_vars.txt file
            % create frameVars matrix
            params.nFrames = numel(XsizeVectorPix);
            frameVars = zeros(params.nFrames,12);
            frameVars(:,1) = 0:params.nFrames-1; % frame number
            frameVars(:,4) = 1; % objType (1=ellipse)
            frameVars(1:numel(XposVectorPix),5) = XposVectorPix;
            frameVars(numel(XposVectorPix)+1:end,5) = XposVectorPix(end);
            frameVars(1:numel(YposVectorPix),6) = YposVectorPix;
            frameVars(numel(YposVectorPix)+1:end,6) = YposVectorPix(end);
            frameVars(:,7) = XsizeVectorPix;
            frameVars(:,8) = YsizeVectorPix;
            frameVars(:,10) = obj.objectColor;
            frameVars(:,12) = 1; % zScaled needs to be 1
            % write to file
            currentDir = cd;
            protocolDir = fileparts(mfilename('fullpath'));
            cd(protocolDir);
            fileID = fopen('frame_vars.txt','w');
            fprintf(fileID,'"frameNum" "objNum" "subFrameNum" "objType(0=box,1=ellipse,2=sphere)" "x" "y" "r1" "r2" "phi" "color" "z" "zScaled"');
            fclose(fileID);
            dlmwrite('frame_vars.txt',frameVars,'delimiter',' ','roffset',1,'-append');
            cd(currentDir);
            params.frame_vars = [protocolDir '/frame_vars.txt'];
            
            % Set number of delay frames for preTime and determine stimTime
            params.delay = round(obj.preTime*frameRate);
            stimTime = nStimFrames/frameRate;
            obj.plotData.stimTime = stimTime;
            
            % Add epoch-specific parameters for ovation
            obj.addParameter('epochObjectDir',epochObjectDir);
            obj.addParameter('epochObjectSpeed',epochObjectSpeed);
            obj.addParameter('epochObjectSize',epochObjectSize);
            obj.addParameter('stimFrames',nStimFrames);
            obj.addParameter('stimTime',stimTime);
            
            % Create a dummy stimulus so the epoch runs for the desired length
            stimulus = zeros(1,floor(obj.rigConfig.sampleRate*(obj.preTime+stimTime+obj.postTime)));
            obj.addStimulus('Amplifier_Ch1','Amplifier_Ch1 stimulus',stimulus,'A');
            
            % Start the StimGL plug-in
            SetParams(obj.stimGL, obj.plugInName, params);
            Start(obj.stimGL, obj.plugInName, 1);
        end
        
        function completeEpoch(obj)
            Stop(obj.stimGL);
            
            % Find spikes
            data=obj.response('Amplifier_Ch1');
            if obj.epochNum==1
                polarity = obj.spikePolThrLimRet(1);
                threshold = obj.spikePolThrLimRet(2);
                limitThresh = obj.spikePolThrLimRet(3);
                returnThresh = obj.spikePolThrLimRet(4);
            else
                polarity = str2double(get(obj.plotData.polarityEditHandle,'String'));
                threshold = str2double(get(obj.plotData.threshEditHandle,'String'));
                limitThresh = str2double(get(obj.plotData.limitEditHandle,'String'));
                returnThresh = str2double(get(obj.plotData.returnEditHandle,'String'));
            end
            % flip data and threshold if negative-going spike peaks
            if polarity<0
                data=-data; 
                threshold=-threshold;
                limitThresh=-limitThresh;
                returnThresh=-returnThresh;
            end
            % find sample number of spike peaks
            obj.plotData.spikePts=[];
            posThreshCross=find(data>=threshold,1);
            while ~isempty(posThreshCross)
                negThreshCross=posThreshCross+find(data(posThreshCross+1:end)<=returnThresh,1);
                if isempty(negThreshCross)
                    break;
                end
                [peak peakIndex]=max(data(posThreshCross:negThreshCross));
                if peak<limitThresh
                    obj.plotData.spikePts(end+1)=posThreshCross-1+peakIndex;
                end
                posThreshCross=negThreshCross+find(data(negThreshCross+1:end)>=threshold,1);
            end
            
            % Update epoch and mean response (spike count) versus object speed and/or direction
            sampInt = 1/obj.rigConfig.sampleRate;
            obj.plotData.time = sampInt-obj.preTime:sampInt:obj.plotData.stimTime+obj.postTime;
            spikeTimes = obj.plotData.time(obj.plotData.spikePts);
            obj.plotData.epochResp = numel(find(spikeTimes>0 & spikeTimes<obj.plotData.stimTime));
            if numel(obj.objectSpeed)>1
                objectSpeedIndex = find(obj.objectSpeed==obj.plotData.epochObjectSpeed,1);
                if isnan(obj.plotData.meanSpeedResp(objectSpeedIndex))
                    obj.plotData.meanSpeedResp(objectSpeedIndex) = obj.plotData.epochResp;
                else
                    obj.plotData.meanSpeedResp(objectSpeedIndex) = mean([repmat(obj.plotData.meanSpeedResp(objectSpeedIndex),1,obj.loopCount-1),obj.plotData.epochResp]);
                end
            end
            if numel(obj.objectDir)>1
                objectDirIndex = find(obj.objectDir==obj.plotData.epochObjectDir,1);
                if isnan(obj.plotData.meanDirResp(objectDirIndex))
                    obj.plotData.meanDirResp(objectDirIndex) = obj.plotData.epochResp;
                else
                    obj.plotData.meanDirResp(objectDirIndex) = mean([repmat(obj.plotData.meanDirResp(objectDirIndex),1,obj.loopCount-1),obj.plotData.epochResp]);
                end
            end
            
            % Call the base class method which updates the figures.
            completeEpoch@SymphonyProtocol(obj);
            
            % if all trial types completed, reset completedTrialTypes and start a new loop
            if isempty(obj.notCompletedTrialTypes)
                obj.notCompletedTrialTypes = 1:size(obj.trialTypes,1);
                obj.loopCount = obj.loopCount+1;
            end
        end
        
        function keepGoing = continueRun(obj)
            % First check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@SymphonyProtocol(obj);
            
            if obj.numberOfLoops>0 && obj.loopCount>obj.numberOfLoops
                keepGoing = false;
            end
            % pause for random inter-epoch interval
            if keepGoing
                rng('shuffle');
                pause on;
                pause(rand(1)*(obj.intertrialIntervalMax-obj.intertrialIntervalMin)+obj.intertrialIntervalMin);
            end
        end
       
        function completeRun(obj)
            Stop(obj.stimGL);
            
            % Call the base class method.
            completeRun@SymphonyProtocol(obj);
        end
        
    end
    
end