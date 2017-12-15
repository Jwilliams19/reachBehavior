function out=readIntensityValues(zonesFile, movieFile)

maxFrames=50000; % max total frames in movie

% Read data in each zone of movie 
% Zones are defined in zonesFile
% What to read from movie in each zone is defined in "takeImageValue" field
% of zones (see options below)
% 'intensity' : get intensity from movie pixels
% 'red' : get red value from movie pixels
% 'green' : get green value from movie pixels
% 'blue' : get blue value from movie pixels

% Read file that specifies zones for current movie
a=load(zonesFile);
zones=a.zones;
% See setup_reach_coding_settings.m for fields

% Read movie file and get intensity values for each
% user-specified zone
% videoFReader=vision.VideoFileReader(movieFile,'PlayCount',1,'ImageColorSpace','YCbCr 4:2:2');
videoFReader=vision.VideoFileReader(movieFile,'PlayCount',1);

% Add user-specified fields to out
for i=1:length(zones)
    out.(zones(i).analysisField)=nan(1,maxFrames);
end
out.changeBetweenFrames=nan(1,maxFrames);

% Read intensities from movie
lastFrame=[];
for i=1:maxFrames
    if mod(i,500)==0
        disp(i);
    end
    [frame,EOF]=step(videoFReader);
    for j=1:length(zones)
        if strcmp(zones(j).takeImageValue,'intensity')
            % Read intensity in this zone
            temp=intensityFromRGB(frame);
            temp=reshape(temp,size(frame,1)*size(frame,2),1);
        elseif strcmp(zones(j).takeImageValue,'red')
            % Read red in this zone
            temp=frame(:,:,1);
            temp=reshape(temp,size(frame,1)*size(frame,2),1);
        elseif strcmp(zones(j).takeImageValue,'green')
            % Read green in this zone
            temp=frame(:,:,2);
            temp=reshape(temp,size(frame,1)*size(frame,2),1);
        elseif strcmp(zones(j).takeImageValue,'blue')
            % Read blue in this zone
            temp=frame(:,:,3);
            temp=reshape(temp,size(frame,1)*size(frame,2),1);
        end
        out.(zones(j).analysisField)(i)=sum(temp(zones(j).isin,:),1);
    end
    frame=intensityFromRGB(frame);
    frame=reshape(frame,size(frame,1)*size(frame,2),1);
    if i==1
        out.changeBetweenFrames(i)=0;
    else
        out.changeBetweenFrames(i)=nansum(nansum(abs(frame-lastFrame),1),2);
    end
    lastFrame=frame;
    if EOF==true
        break
    end
end

% Pad changeBetweenFrames
out.changeBetweenFrames(1)=out.changeBetweenFrames(2);

end

function intensity=intensityFromRGB(frame)

intensity=0.299*frame(:,:,1)+0.587*frame(:,:,2)+0.114*frame(:,:,3);

end