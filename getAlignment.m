function aligned=getAlignment(out,moviefps,handles)

distractorType='fixed duration';
% distractorType='random';

% Note that microSD (Arduino) output is timed in ms
% Whereas video is timed in frames per sec

% Remove incomplete reach detections
isnotnaninds=~isnan(mean([handles.reachStarts' handles.pelletTime' handles.eatTime' handles.pelletMissing'],2));
handles.reachStarts=handles.reachStarts(isnotnaninds);
handles.pelletTouched=handles.pelletTouched(isnotnaninds);
handles.pelletTime=handles.pelletTime(isnotnaninds);
handles.atePellet=handles.atePellet(isnotnaninds);
handles.eatTime=handles.eatTime(isnotnaninds);
handles.pelletMissing=handles.pelletMissing(isnotnaninds);

% Try to align based on distractor LED from movie and Arduino output
temp_LED=handles.LEDvals;
threshForOnVsOff=nanmean([max(temp_LED) min(temp_LED)]);
figure();
movie_times=0:(1/moviefps)*1000:(length(temp_LED)-1)*((1/moviefps)*1000);
plot(movie_times,temp_LED,'Color','b');
hold on;
line([0 (length(temp_LED)-1)*((1/moviefps)*1000)],[threshForOnVsOff threshForOnVsOff],'Color','r');
title('Threshold for distinguishing LED on vs off');

% Get when LED was on in movie vs off
movie_LED=temp_LED>threshForOnVsOff;

% Find best alignment of distractor LED in movie and Arduino output -- note
% different sampling rates
temp=out.distractorOn';
testRunLED=out.distractorOn;
% arduino_timestep=out.allTrialTimes(1,2)-out.allTrialTimes(1,1); % in ms
% temptimes=(out.allTrialTimes+repmat(out.trialStartTimes',1,size(out.allTrialTimes,2)))';

temptimes=[];
for i=1:size(out.allTrialTimes,1)
    temptimes=[temptimes out.allTrialTimes(i,:)];
end
% temptimes=out.allTrialTimes;
% temptimes=temptimes(1:end);
temp=temp(1:end);
arduino_LED=temp(~isnan(temptimes));
arduino_times=temptimes(~isnan(temptimes));

% Find alignment
% First down-sample arduino LED

if strcmp(distractorType,'fixed duration')
    arduino_dec=33;
    movie_dec=1;
else
    arduino_dec=100;
    movie_dec=3;
end

arduino_LED=decimate(arduino_LED,arduino_dec);
arduino_dec_times=decimate(arduino_times,arduino_dec);

testRun_movieLED=double(movie_LED);

movie_LED=decimate(double(movie_LED),movie_dec);
movie_times=decimate(movie_times,movie_dec);

% Do an initial alignment
if strcmp(distractorType,'fixed duration')
    temp=arduino_LED;
    arduino_LED(temp>=0.5)=1;
    arduino_LED(temp<0.5)=0;
    temp=movie_LED;
    movie_LED(temp>=0.5)=1;
    movie_LED(temp<0.5)=0;
    
    [pks_arduino,locs_arduino]=findpeaks(arduino_LED);
    arduino_LED_ITIs=diff(arduino_times(locs_arduino));
    [pks,locs]=findpeaks(movie_LED);
    movie_LED_ITIs=diff(movie_times(locs));
    
%     figure();
%     plot(arduino_LED_ITIs,'Color','r');
%     figure();
%     plot(movie_LED_ITIs,'Color','b');
    
    [X,Y,D]=alignsignals(arduino_LED_ITIs./max(arduino_LED_ITIs),movie_LED_ITIs./max(movie_LED_ITIs));
    tryinc=0.0001;
    if D>0
        error('Why does movie start before Arduino?');
    else
        movie_peakloc=1;
        arduino_peakloc=abs(D)+1;
        movie_peak_indexIntoMovie=locs(movie_peakloc);
        arduino_peak_indexIntoArduino=locs_arduino(arduino_peakloc);
        size_of_arduino=length(arduino_LED(locs_arduino((-D)+1):locs_arduino((-D)+1+length(movie_LED_ITIs))));
        size_of_movie=length(movie_LED(locs(1):end));
        guess_best_scale=size_of_arduino/size_of_movie;
        % Adjust according to guess_best_scale
        movie_LED=resample(movie_LED,floor(mod(size_of_arduino/size_of_movie,1)*100)+floor((guess_best_scale*100)/100)*100,100);
        guess_best_delay=arduino_peak_indexIntoArduino-movie_peak_indexIntoMovie;
%         trydelays=guess_best_delay-50:guess_best_delay+50;
        trydelays=guess_best_delay-15:guess_best_delay+15;
        % Note that fixed, so now best scale is 1
        guess_best_scale=1;
        tryscales=guess_best_scale-0.003:tryinc:guess_best_scale+0.003;
        backup_movie_LED=movie_LED; 
    end    
    
    figure();
    plot(X,'Color','b');
    hold on; 
    plot(Y,'Color','r');
    
    figure();
    plot(arduino_LED,'Color','b');
    hold on;
    plot([nan(1,guess_best_delay) movie_LED],'Color','r');
else
    maxDelay=length(arduino_LED)-length(movie_LED);
    trydelays=1:maxDelay;
    minscale=1; % scale movie wrt arduino time
    maxscale=2.5;
    tryinc=0.02;
    tryscales=minscale:tryinc:maxscale;
end

% Test signal alignment and scaling
sumdiffs=nan(length(tryscales),length(trydelays));
backup_movie_LED=movie_LED;
backup_arduino_LED=arduino_LED;
for j=1:length(tryscales)
    if mod(j,10)==0
        disp('Processing ...');
%         disp(j);
    end
    currscale=tryscales(j);
    movie_LED=resample(backup_movie_LED,floor(currscale*(1/tryinc)),floor((1/tryinc)));
    for i=1:length(trydelays)
        currdelay=trydelays(i);
        if mod(i,500)==0
%             disp(i);
        end 
        temp_movie=[nan(1,currdelay) movie_LED];
        temp_arduino=[arduino_LED nan(1,length(temp_movie)-length(arduino_LED))];
        if length(temp_arduino)>length(temp_movie)
            temp_movie=[temp_movie nan(1,length(temp_arduino)-length(temp_movie))];
%             sumdiffs(j,i)=nansum(abs(temp_movie-temp_arduino));
%             temp_temp_movie=temp_movie;
%             temp_temp_movie(isnan(temp_temp_movie))=0;
%             temp_temp_arduino=temp_arduino;
%             temp_temp_arduino(isnan(temp_temp_arduino))=0;
            sumdiffs(j,i)=nansum(abs(temp_movie-temp_arduino));
        elseif length(temp_movie)>length(temp_arduino)
            % This should not happen
            % Arduino should include movie
            sumdiffs(j,i)=inf;
            error('Why is movie longer than Arduino?');
        else
            sumdiffs(j,i)=nansum(abs(temp_movie-temp_arduino)); 
        end
    end
end
sumdiffs(isinf(sumdiffs))=nan;
ma=max(sumdiffs(:));
sumdiffs(isnan(sumdiffs))=3*ma;
[minval,mi]=min(sumdiffs(:));
[mi_row,mi_col]=ind2sub(size(sumdiffs),mi);

figure(); 
imagesc(sumdiffs);
title('Finding best alignment');

frontShift=trydelays(mi_col);
scaleBy=tryscales(mi_row);
resampFac=1/tryinc;
best_movie=[nan(1,trydelays(mi_col)) resample(backup_movie_LED,floor(tryscales(mi_row)*(1/tryinc)),floor(1/tryinc))];
shouldBeLength=length(best_movie);
best_arduino=[backup_arduino_LED nan(1,length(best_movie)-length(backup_arduino_LED))];
movieToLength=length(best_arduino);
if length(best_arduino)>length(best_movie)
    best_movie=[best_movie nan(1,length(best_arduino)-length(best_movie))];
end
figure();
plot(best_movie,'Color','b');
hold on;
plot(best_arduino,'Color','r');

% disp('in original alignment');
% disp(length(best_arduino))
 
% Then re-align sub-sections of movie to arduino code
alignSegments=750; % in number of indices
% alignSegments=250; % in number of indices
mov_distractor=[];
arduino_distractor=[];
firstInd=find(~isnan(best_movie) & ~isnan(best_arduino),1,'first');
lastBoth=min([find(~isnan(best_movie),1,'last') find(~isnan(best_arduino),1,'last')]);
segmentInds=firstInd:floor(alignSegments/2):lastBoth;
allMatchedInds=firstInd:lastBoth;
mov_distractor=[mov_distractor nan(1,firstInd-1)];
arduino_distractor=[arduino_distractor nan(1,firstInd-1)];
segmentDelays=nan(1,length(segmentInds));
addZeros_movie=nan(1,length(segmentInds));
addZeros_arduino=nan(1,length(segmentInds));
moveChunks=nan(length(segmentInds),2);
tookTheseIndsOfTemp1=floor(0.25*alignSegments):ceil(0.75*alignSegments);
haveDoneTheseInds=zeros(size(firstInd:lastBoth));
backup_tookTheseIndsOfTemp1=tookTheseIndsOfTemp1;
for i=1:length(segmentInds)-1
    currInd=segmentInds(i);
    [temp1,temp2,D]=alignsignals(best_movie(currInd:currInd+alignSegments-1),best_arduino(currInd:currInd+alignSegments-1));
    segmentDelays(i)=D;
    if length(temp1)>length(temp2)
        addZeros_arduino(i)=length(temp1)-length(temp2);
        temp2=[temp2 temp2(end)*ones(1,length(temp1)-length(temp2))];
        addZeros_movie(i)=0;
    elseif length(temp2)>length(temp1)
        addZeros_movie(i)=length(temp2)-length(temp1);
        temp1=[temp1 temp1(end)*ones(1,length(temp2)-length(temp1))];
        addZeros_arduino(i)=0;
    else
        addZeros_movie(i)=0;
        addZeros_arduino(i)=0;
    end
    % Take middle of aligned segments, because alignment at middle tends to
    % be better than alignment at edges
    temp_startInd=find(haveDoneTheseInds==0,1,'first');
    currIndices=currInd:(currInd+alignSegments-1);
    tookTheseIndsOfTemp1(1)=allMatchedInds(temp_startInd)-currIndices(1)+1;
    tookTheseIndsOfTemp1(end)=backup_tookTheseIndsOfTemp1(end);
    temp_endInd=temp_startInd+(tookTheseIndsOfTemp1(end)-tookTheseIndsOfTemp1(1));
    if i==1
        haveDoneTheseInds(1:temp_endInd)=1;
    else
        haveDoneTheseInds(temp_startInd:temp_endInd)=1;
    end
    if i==1
        startAt=1;
        if D>0 % temp1 has been delayed by D samples
            endAt=tookTheseIndsOfTemp1(end)+D;
%             endAt=tookTheseIndsOfTemp1(end);
        else % temp2 has been delayed by D samples
            endAt=tookTheseIndsOfTemp1(end);
%             endAt=tookTheseIndsOfTemp1(end)-D;
        end
    elseif i==length(segmentInds)-1
        % alignment easily messed up at end -- just use delay from previous
        % segment
        if segmentDelays(i-1)>0 
            temp1=[ones(1,segmentDelays(i-1))*temp1(1) temp1];
        else
            temp2=[ones(1,-segmentDelays(i-1))*temp2(1) temp2];
        end
        segmentDelays(i)=segmentDelays(i-1);
        D=segmentDelays(i);
        if D>0 % temp1 has been delayed by D samples
            startAt=tookTheseIndsOfTemp1(1)+D;
%             startAt=tookTheseIndsOfTemp1(1);
        else % temp2 has been delayed by D samples
            startAt=tookTheseIndsOfTemp1(1);
%             startAt=tookTheseIndsOfTemp1(1)-D;
        end
        endAt=min([length(temp1) length(temp2)]);        
    else
        if D>0 % temp1 has been delayed by D samples
            startAt=tookTheseIndsOfTemp1(1)+D; 
            endAt=tookTheseIndsOfTemp1(end)+D;
%             startAt=tookTheseIndsOfTemp1(1); 
%             endAt=tookTheseIndsOfTemp1(end);
        else % temp2 has been delayed by D samples
            startAt=tookTheseIndsOfTemp1(1); 
            endAt=tookTheseIndsOfTemp1(end);
%             startAt=tookTheseIndsOfTemp1(1)-D; 
%             endAt=tookTheseIndsOfTemp1(end)-D;
        end
    end
    temp1=temp1(startAt:endAt);
    temp2=temp2(startAt:endAt);
    moveChunks(i,1)=startAt;
    moveChunks(i,2)=endAt;
    mov_distractor=[mov_distractor temp1];
    arduino_distractor=[arduino_distractor temp2];
end
figure();
plot(mov_distractor,'Color','b');
hold on;
plot(arduino_distractor,'Color','r');
aligned.movie_distractor=mov_distractor;
aligned.arduino_distractor=arduino_distractor;


% Align other signals in same fashion as LED distractor
% From Arduino

% Make cue ONLY the *start* of cue
for i=1:size(out.cueOn,1)
    temp=zeros(size(out.cueOn(i,:)));
    temp(isnan(out.cueOn(i,:)))=nan;
    temp(find(out.cueOn(i,:)>0.5,1,'first'))=1;
    out.cueOn(i,:)=temp;
end

temp=out.cueOn';
temp=temp(1:end);
cue=temp(~isnan(temptimes));
cue=alignLikeDistractor(cue,0,arduino_dec,frontShift,shouldBeLength,movieToLength,alignSegments,segmentInds,segmentDelays,addZeros_arduino,scaleBy,resampFac,moveChunks); 
aligned.cue=cue./nanmax(cue);

temp=testRunLED';
temp=temp(1:end);
testRunDistractor=temp(~isnan(temptimes));
testRunDistractor=alignLikeDistractor(testRunDistractor,0,arduino_dec,frontShift,shouldBeLength,movieToLength,alignSegments,segmentInds,segmentDelays,addZeros_arduino,scaleBy,resampFac,moveChunks); 
aligned.testRunDistractor=testRunDistractor./nanmax(testRunDistractor);

temp=out.pelletLoaded';
temp=temp(1:end);
pelletLoaded=temp(~isnan(temptimes));
pelletLoaded=alignLikeDistractor(pelletLoaded,0,arduino_dec,frontShift,shouldBeLength,movieToLength,alignSegments,segmentInds,segmentDelays,addZeros_arduino,scaleBy,resampFac,moveChunks); 
aligned.pelletLoaded=pelletLoaded./nanmax(pelletLoaded);
temp=out.pelletPresented';
temp=temp(1:end);
pelletPresented=temp(~isnan(temptimes));
pelletPresented=alignLikeDistractor(pelletPresented,0,arduino_dec,frontShift,shouldBeLength,movieToLength,alignSegments,segmentInds,segmentDelays,addZeros_arduino,scaleBy,resampFac,moveChunks); 
aligned.pelletPresented=pelletPresented./nanmax(pelletPresented);
temp=out.encoderTrialVals';
temp=temp(1:end);
encoder=temp(~isnan(temptimes));
encoder=alignLikeDistractor(encoder,0,arduino_dec,frontShift,shouldBeLength,movieToLength,alignSegments,segmentInds,segmentDelays,addZeros_arduino,scaleBy,resampFac,moveChunks); 
aligned.encoder=encoder;
temp=out.nDropsPerTrial';
temp=temp(1:end);
drops=temp(~isnan(temptimes));
drops=alignLikeDistractor(drops,0,arduino_dec,frontShift,shouldBeLength,movieToLength,alignSegments,segmentInds,segmentDelays,addZeros_arduino,scaleBy,resampFac,moveChunks); 
aligned.drops=drops;
temp=out.nMissesPerTrial';
temp=temp(1:end);
misses=temp(~isnan(temptimes));
misses=alignLikeDistractor(misses,0,arduino_dec,frontShift,shouldBeLength,movieToLength,alignSegments,segmentInds,segmentDelays,addZeros_arduino,scaleBy,resampFac,moveChunks); 
aligned.misses=misses;
timesfromarduino=alignLikeDistractor(double(arduino_times),0,arduino_dec,frontShift,shouldBeLength,movieToLength,alignSegments,segmentInds,segmentDelays,addZeros_arduino,scaleBy,resampFac,moveChunks); 
aligned.timesfromarduino=timesfromarduino;
% From movie
temp=1:length(handles.LEDvals);
movieframeinds_raw=double(handles.discardFirstNFrames+temp);
movieframeinds=alignLikeDistractor(movieframeinds_raw,1,movie_dec,frontShift,shouldBeLength,movieToLength,alignSegments,segmentInds,segmentDelays,addZeros_movie,scaleBy,resampFac,moveChunks);
movieframeinds_backup=movieframeinds;

testRunDistractor_movie=alignLikeDistractor(testRun_movieLED,1,movie_dec,frontShift,shouldBeLength,movieToLength,alignSegments,segmentInds,segmentDelays,addZeros_movie,scaleBy,resampFac,moveChunks);
aligned.testRunDistractor_movie=testRunDistractor_movie;


% Re-align movie frame inds based on alignment to non-interped LED vals
maxNFramesForLEDtoChange=2;
deriv_LEDvals=[diff(handles.LEDvals) 0];
% deriv_thresh=(nanmean(handles.LEDvals))/(maxNFramesForLEDtoChange+1);
deriv_thresh=(max(handles.LEDvals)/4)/(maxNFramesForLEDtoChange+1);
[pks,locs]=findpeaks(deriv_LEDvals);
peakLocs=locs(pks>deriv_thresh);
tooclose=diff(peakLocs);
peakLocs=peakLocs(tooclose>=3*maxNFramesForLEDtoChange);
[pks,locs]=findpeaks(-deriv_LEDvals);
troughLocs=locs(pks>deriv_thresh);
tooclose=diff(troughLocs);
troughLocs=troughLocs(tooclose>=3*maxNFramesForLEDtoChange);
rawmovieinds_onto_rescaled=nan(size(movieframeinds));
if movieframeinds_raw(peakLocs(1))<movieframeinds_raw(troughLocs(1))
    % LED first increases
else
    % LED first decreases
    % Throw out first decrease
    troughLocs=troughLocs(2:end);
end
if length(peakLocs)>length(troughLocs)
    peakLocs=peakLocs(1:length(troughLocs));
end
if movieframeinds_raw(peakLocs(1))>=movieframeinds_raw(troughLocs(1))
    error('Problem in raw LED values -- should always turn on, then off');
end
rescaled_thresh=0.5;
deriv_LEDvals_rescaled=[diff(aligned.movie_distractor) 0];
[pks,locs]=findpeaks(deriv_LEDvals_rescaled);
peakLocs_rescaled=locs(pks>rescaled_thresh);
tooclose=diff(peakLocs_rescaled);
peakLocs_rescaled=peakLocs_rescaled(tooclose>=3*maxNFramesForLEDtoChange);
peakTimes_rescaled=movieframeinds(peakLocs_rescaled);
[pks,locs]=findpeaks(-deriv_LEDvals_rescaled);
troughLocs_rescaled=locs(pks>rescaled_thresh);
tooclose=diff(troughLocs_rescaled);
troughLocs_rescaled=troughLocs_rescaled(tooclose>=3*maxNFramesForLEDtoChange);
troughTimes_rescaled=movieframeinds(troughLocs_rescaled);
if peakTimes_rescaled(1)<troughTimes_rescaled(1)
    % LED first increases
else
    % LED first decreases
    % Throw out first decrease
    troughLocs_rescaled=troughLocs_rescaled(2:end);
    troughTimes_rescaled=troughTimes_rescaled(2:end);
end
if length(peakLocs_rescaled)>length(troughLocs_rescaled)
    peakLocs_rescaled=peakLocs_rescaled(1:length(troughLocs_rescaled));
    peakTimes_rescaled=peakTimes_rescaled(1:length(troughLocs_rescaled));
end
k=1;
for i=1:length(peakLocs)
    up=movieframeinds_raw(peakLocs(i));
    down=movieframeinds_raw(troughLocs(i));
    [~,mi_up]=min(abs(peakTimes_rescaled-up));
    [~,mi_down]=min(abs(troughTimes_rescaled-down));
    rawmovieinds_onto_rescaled(peakLocs_rescaled(k):troughLocs_rescaled(k))=linspace(up,down,troughLocs_rescaled(k)-peakLocs_rescaled(k)+1);
    k=k+1;
end
% Fill in nans accordingly
firstnan=find(isnan(rawmovieinds_onto_rescaled),1,'first');
temp=rawmovieinds_onto_rescaled;
temp(1:firstnan)=nan;
firstnotnan=find(~isnan(temp),1,'first');
safety_counter=1;
rawframestart=movieframeinds_raw(1);
while ~isempty(firstnan)
    if safety_counter>20*10^4
        break
    end
    if isempty(rawmovieinds_onto_rescaled(firstnotnan))
        temp=linspace(rawframestart,movieframeinds_raw(end),length(rawmovieinds_onto_rescaled)-firstnan+2);
        rawmovieinds_onto_rescaled(firstnan:length(rawmovieinds_onto_rescaled))=temp(2:end);
        break
    end
    temp=linspace(rawframestart,rawmovieinds_onto_rescaled(firstnotnan),firstnotnan-firstnan+2);
    rawmovieinds_onto_rescaled(firstnan:firstnotnan-1)=temp(2:end-1);
    % Increment
    firstnan=find(isnan(rawmovieinds_onto_rescaled),1,'first');
    rawframestart=rawmovieinds_onto_rescaled(firstnan-1);
    temp=rawmovieinds_onto_rescaled;
    temp(1:firstnan)=nan;
    firstnotnan=find(~isnan(temp),1,'first');
    safety_counter=safety_counter+1;
end
aligned.movieframeinds=rawmovieinds_onto_rescaled;
% aligned.movieframeinds=movieframeinds_backup;

% Plot results
figure();
ha=tight_subplot(7,1,[0.06 0.03],[0.08 0.1],[0.1 0.01]);
currha=ha(1);
axes(currha);
plot(aligned.cue,'Color','r');
xlabel('Cue');
set(currha,'XTickLabel','');
% set(currha,'YTickLabel','');
title('Results of alignment');

currha=ha(2);
axes(currha);
plot(aligned.movie_distractor,'Color','b');
hold on;
plot(aligned.arduino_distractor,'Color','r');
xlabel('Distractor');
set(currha,'XTickLabel','');
% set(currha,'YTickLabel','');

currha=ha(3);
axes(currha);
plot(aligned.movieframeinds,'Color','b');
xlabel('Movie frames');
set(currha,'XTickLabel','');
% set(currha,'YTickLabel','');

currha=ha(4);
axes(currha);
plot(aligned.pelletLoaded,'Color','r');
xlabel('Pellet loaded');
set(currha,'XTickLabel','');
% set(currha,'YTickLabel','');

currha=ha(5);
axes(currha);
plot(aligned.pelletPresented,'Color','r');
xlabel('Pellet presented');
set(currha,'XTickLabel','');
% set(currha,'YTickLabel','');

currha=ha(6);
axes(currha);
plot(aligned.timesfromarduino./1000,'Color','r');
xlabel('Times from arduino');
set(currha,'XTickLabel','');
% set(currha,'YTickLabel','');

currha=ha(7);
axes(currha);
plot(aligned.movieframeinds.*(1/moviefps),'Color','b');
xlabel('Times from movie');
set(currha,'XTickLabel','');
% set(currha,'YTickLabel','');
end

function X = naninterp(X) 

% Interpolate over NaNs 
X(isnan(X)) = interp1(find(~isnan(X)), X(~isnan(X)), find(isnan(X)), 'cubic'); 
return 

end

function outsignal=alignLikeDistractor(signal,scaleThisSignal,decind,frontShift,shouldBeLength,movieToLength,alignSegments,segmentInds,segmentDelays,addZeros,scaleBy,resampFac,moveChunks)

% If like movie, scaleThisSignal=1
% else scaleThisSignal=0

signal=decimate(signal,decind);
if scaleThisSignal==1
    % Like movie
    temp=resample(signal,floor(scaleBy*resampFac),floor(resampFac));
    % cut off ringing artifact
    temp(end-10+1:end)=nan;
    signal=[nan(1,frontShift) temp];
    if movieToLength>length(signal)
        signal=[signal nan(1,movieToLength-length(signal))];
    end
else
    % Like arduino
    signal=[signal nan(1,shouldBeLength-length(signal))];
end

% [Xa,Ya] = alignsignals(X,Y)
% X is movie, Y is arduino
% If Y is delayed with respect to X, then D is positive and X is delayed by D samples.
% If Y is advanced with respect to X, then D is negative and Y is delayed by �D samples.

% disp('in second alignment');
% disp(length(signal))

outsignal=[];
firstInd=segmentInds(1);
outsignal=[outsignal zeros(1,firstInd-1)];
for i=1:length(segmentInds)-1
    currInd=segmentInds(i);
    currChunk=signal(currInd:currInd+alignSegments-1);
    if scaleThisSignal==1
        % Like movie
        if segmentDelays(i)>0
            % Delay is positive, so movie was shifted
            currChunk=[ones(1,segmentDelays(i))*currChunk(1) currChunk];
        else
            % Delay is negative, so arduino was shifted
        end
    else
        % Like arduino
        if segmentDelays(i)>0
            % Delay is positive, so movie was shifted
        else
            % Delay is negative, so arduino was shifted
            currChunk=[ones(1,-segmentDelays(i))*currChunk(1) currChunk];
        end 
    end
    currChunk=[currChunk currChunk(end)*ones(1,addZeros(i))];
    currChunk=currChunk(moveChunks(i,1):moveChunks(i,2));
    outsignal=[outsignal currChunk];
end

end
