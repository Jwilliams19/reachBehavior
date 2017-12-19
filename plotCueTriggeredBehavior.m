function tbt=plotCueTriggeredBehavior(data,nameOfCue,excludePawOnWheelTrials)

% nameOfCue should be 'cue' for real cue
% 'arduino_distractor' for distractor

cue=data.(nameOfCue); 
% In case of issues with aliasing of instantaneous cue
maxITI=30; % in seconds, maximal ITI
minITI=2; % in seconds, minimal ITI
% Get time delay
timeIncs=diff(data.timesfromarduino(data.timesfromarduino~=0));
mo=mode(timeIncs);
timeIncs(timeIncs==mo)=nan;
bettermode=mode(timeIncs); % in ms
bettermode=bettermode/1000; % in seconds

[cue,cueInds,cueIndITIs]=fixAliasing(cue,maxITI,minITI,bettermode);
[data.pelletPresented,presentedInds]=fixAliasing(data.pelletPresented,maxITI,minITI,bettermode);

smallestTrial=min(cueIndITIs(cueIndITIs>10)); 

figure();
plot(cue./nanmax(cue));
hold on;
plot(data.pelletPresented./nanmax(data.pelletPresented),'Color','k');
for i=1:length(cueInds)
    scatter(cueInds(i),1,[],'r');
end
for i=1:length(presentedInds)
    scatter(presentedInds(i),1,[],[0.5 0.5 0.5]);
end
title('Checking cue selection');

% Get data
distractor=data.arduino_distractor;
pelletLoaded=data.pelletLoaded;
pelletPresented=data.pelletPresented;
reachStarts=data.reachStarts;
reach_ongoing=data.reach_ongoing;
success=data.success_reachStarts;
drop=data.drop_reachStarts;
miss=data.miss_reachStarts;
eating=data.eating;
reach_wout_pellet=data.pelletmissingreach_reachStarts;
timesFromArduino=data.timesfromarduino; % in ms
timesFromArduino=timesFromArduino./1000; % in seconds
movieframeinds=data.movieframeinds;
paw_from_wheel=data.pawOnWheel;
success_pawOnWheel=data.success_reachStarts_pawOnWheel;
drop_pawOnWheel=data.drop_reachStarts_pawOnWheel;
miss_pawOnWheel=data.miss_reachStarts_pawOnWheel;
reach_pelletPresent=data.reachStarts_pelletPresent;

% Turn pellet presented into events
sigmax=max(max(pelletPresented));
sigthresh=sigmax/2;
temp=zeros(size(pelletPresented));
temp(pelletPresented>=sigthresh)=1;
pelletPresented=temp;

% Trial-by-trial, tbt
pointsFromPreviousTrial=100;
cue_tbt=nan(length(cueInds),max(cueIndITIs)+pointsFromPreviousTrial);
distractor_tbt=nan(length(cueInds),max(cueIndITIs)+pointsFromPreviousTrial);
pelletLoaded_tbt=nan(length(cueInds),max(cueIndITIs)+pointsFromPreviousTrial);
pelletPresented_tbt=nan(length(cueInds),max(cueIndITIs)+pointsFromPreviousTrial);
reachStarts_tbt=nan(length(cueInds),max(cueIndITIs)+pointsFromPreviousTrial);
reach_ongoing_tbt=nan(length(cueInds),max(cueIndITIs)+pointsFromPreviousTrial);
success_tbt=nan(length(cueInds),max(cueIndITIs)+pointsFromPreviousTrial);
drop_tbt=nan(length(cueInds),max(cueIndITIs)+pointsFromPreviousTrial);
miss_tbt=nan(length(cueInds),max(cueIndITIs)+pointsFromPreviousTrial);
eating_tbt=nan(length(cueInds),max(cueIndITIs)+pointsFromPreviousTrial);
times_tbt=nan(length(cueInds),max(cueIndITIs)+pointsFromPreviousTrial);
movieframeinds_tbt=nan(length(cueInds),max(cueIndITIs)+pointsFromPreviousTrial);
reach_wout_pellet_tbt=nan(length(cueInds),max(cueIndITIs)+pointsFromPreviousTrial);
paw_from_wheel_tbt=nan(length(cueInds),max(cueIndITIs)+pointsFromPreviousTrial);
success_pawOnWheel_tbt=nan(length(cueInds),max(cueIndITIs)+pointsFromPreviousTrial);
drop_pawOnWheel_tbt=nan(length(cueInds),max(cueIndITIs)+pointsFromPreviousTrial);
miss_pawOnWheel_tbt=nan(length(cueInds),max(cueIndITIs)+pointsFromPreviousTrial);
reach_pelletPresent_tbt=nan(length(cueInds),max(cueIndITIs)+pointsFromPreviousTrial);
    

for i=1:length(cueInds)
    if i==length(cueInds)
        theseInds=cueInds(i)-pointsFromPreviousTrial:length(cue);
    elseif i==1
        theseInds=1:cueInds(i+1)-1;
    else
        theseInds=cueInds(i)-pointsFromPreviousTrial:cueInds(i+1)-1;
    end
    cue_tbt(i,1:length(theseInds))=cue(theseInds);
    distractor_tbt(i,1:length(theseInds))=distractor(theseInds);
    pelletLoaded_tbt(i,1:length(theseInds))=pelletLoaded(theseInds);
    pelletPresented_tbt(i,1:length(theseInds))=pelletPresented(theseInds);
    reachStarts_tbt(i,1:length(theseInds))=reachStarts(theseInds);
    reach_ongoing_tbt(i,1:length(theseInds))=reach_ongoing(theseInds);
    success_tbt(i,1:length(theseInds))=success(theseInds);
    drop_tbt(i,1:length(theseInds))=drop(theseInds);
    miss_tbt(i,1:length(theseInds))=miss(theseInds);
    eating_tbt(i,1:length(theseInds))=eating(theseInds); 
%     times_tbt(i,1:length(theseInds))=timesFromArduino(theseInds); 
    times_tbt(i,1:length(theseInds))=movieframeinds(theseInds).*bettermode;
    movieframeinds_tbt(i,1:length(theseInds))=movieframeinds(theseInds); 
    reach_wout_pellet_tbt(i,1:length(theseInds))=reach_wout_pellet(theseInds); 
    paw_from_wheel_tbt(i,1:length(theseInds))=paw_from_wheel(theseInds); 
    success_pawOnWheel_tbt(i,1:length(theseInds))=success_pawOnWheel(theseInds); 
    drop_pawOnWheel_tbt(i,1:length(theseInds))=drop_pawOnWheel(theseInds); 
    miss_pawOnWheel_tbt(i,1:length(theseInds))=miss_pawOnWheel(theseInds); 
    reach_pelletPresent_tbt(i,1:length(theseInds))=reach_pelletPresent(theseInds); 
end

% cue_tbt=cue_tbt(:,1:smallestTrial);
% distractor_tbt=distractor_tbt(:,1:smallestTrial);
% pelletLoaded_tbt=pelletLoaded_tbt(:,1:smallestTrial);
% pelletPresented_tbt=pelletPresented_tbt(:,1:smallestTrial);
% reachStarts_tbt=reachStarts_tbt(:,1:smallestTrial);
% reach_ongoing_tbt=reach_ongoing_tbt(:,1:smallestTrial);
% success_tbt=success_tbt(:,1:smallestTrial);
% drop_tbt=drop_tbt(:,1:smallestTrial);
% miss_tbt=miss_tbt(:,1:smallestTrial);
% eating_tbt=eating_tbt(:,1:smallestTrial);
% times_tbt=times_tbt(:,1:smallestTrial);
% movieframeinds_tbt=movieframeinds_tbt(:,1:smallestTrial);

% Zero out
cue_tbt(isnan(cue_tbt))=0;
distractor_tbt(isnan(distractor_tbt))=0;
pelletLoaded_tbt(isnan(pelletLoaded_tbt))=0;
pelletPresented_tbt(isnan(pelletPresented_tbt))=0;
reachStarts_tbt(isnan(reachStarts_tbt))=0;
reach_ongoing_tbt(isnan(reach_ongoing_tbt))=0;
success_tbt(isnan(success_tbt))=0;
drop_tbt(isnan(drop_tbt))=0;
miss_tbt(isnan(miss_tbt))=0;
eating_tbt(isnan(eating_tbt))=0;
reach_wout_pellet_tbt(isnan(eating_tbt))=0;
paw_from_wheel_tbt(isnan(paw_from_wheel_tbt))=0;
success_pawOnWheel_tbt(isnan(success_pawOnWheel_tbt))=0;
drop_pawOnWheel_tbt(isnan(drop_pawOnWheel_tbt))=0;
miss_pawOnWheel_tbt(isnan(miss_pawOnWheel_tbt))=0;
reach_pelletPresent_tbt(isnan(reach_pelletPresent_tbt))=0;

% Take only trials where movie video also available
% isemptytrials=isnan(nanmean(movieframeinds_tbt,2));
% cue_tbt=cue_tbt(~isemptytrials,:);
% distractor_tbt=distractor_tbt(~isemptytrials,:);
% pelletLoaded_tbt=pelletLoaded_tbt(~isemptytrials,:);
% pelletPresented_tbt=pelletPresented_tbt(~isemptytrials,:);
% reachStarts_tbt=reachStarts_tbt(~isemptytrials,:);
% reach_ongoing_tbt=reach_ongoing_tbt(~isemptytrials,:);
% success_tbt=success_tbt(~isemptytrials,:);
% drop_tbt=drop_tbt(~isemptytrials,:);
% miss_tbt=miss_tbt(~isemptytrials,:);
% eating_tbt=eating_tbt(~isemptytrials,:);
% times_tbt=times_tbt(~isemptytrials,:);
% movieframeinds_tbt=movieframeinds_tbt(~isemptytrials,:);

tbt.cue_tbt=cue_tbt;
tbt.distractor_tbt=distractor_tbt;
tbt.pelletLoaded_tbt=pelletLoaded_tbt;
tbt.pelletPresented_tbt=pelletPresented_tbt;
tbt.reachStarts_tbt=reachStarts_tbt;
tbt.reach_ongoing_tbt=reach_ongoing_tbt;
tbt.success_tbt=success_tbt;
tbt.drop_tbt=drop_tbt;
tbt.miss_tbt=miss_tbt;
tbt.eating_tbt=eating_tbt;
tbt.times_tbt=times_tbt;
tbt.movieframeinds_tbt=movieframeinds_tbt;
tbt.reach_wout_pellet_tbt=reach_wout_pellet_tbt;
tbt.paw_from_wheel_tbt=paw_from_wheel_tbt;
tbt.success_pawOnWheel_tbt=success_pawOnWheel_tbt;
tbt.drop_pawOnWheel_tbt=drop_pawOnWheel_tbt;
tbt.miss_pawOnWheel_tbt=miss_pawOnWheel_tbt;
tbt.reach_pelletPresent_tbt=reach_pelletPresent_tbt;

times_tbt=times_tbt-repmat(nanmin(times_tbt,[],2),1,size(times_tbt,2));
timespertrial=nanmean(times_tbt,1);
% timespertrial=1:length(timespertrial);

% Exclude trials where paw was on wheel while wheel turning
if excludePawOnWheelTrials==1
    % Find trials where paw was on wheel while wheel turning
    plot_cues=[];
    for i=1:size(cue_tbt,1)
        presentInd=find(pelletPresented_tbt(i,:)>0.5,1,'first');
        cueInd=find(cue_tbt(i,:)>0.5,1,'first');
        pawWasOnWheel=0;
        if any(paw_from_wheel_tbt(i,presentInd:cueInd)>0.5)
            pawWasOnWheel=1;
        else
            plot_cues=[plot_cues i];
        end
    end
else
    plot_cues=1:size(cue_tbt,1);
end

% Plot
figure();
ha=tight_subplot(11,1,[0.06 0.03],[0.05 0.05],[0.1 0.03]);
currha=ha(1);
axes(currha);
plot(timespertrial,nanmean(cue_tbt(plot_cues,:),1));
title('cue');

currha=ha(2);
axes(currha);
plot(timespertrial,nanmean(reachStarts_tbt(plot_cues,:),1));
title('reachStarts');

currha=ha(3);
axes(currha);
plot(timespertrial,nanmean(distractor_tbt(plot_cues,:),1));
title('distractor');

currha=ha(4);
axes(currha);
plot(timespertrial,nanmean(reach_ongoing_tbt(plot_cues,:),1));
title('reach ongoing');

currha=ha(5);
axes(currha);
plot(timespertrial,nanmean(success_tbt(plot_cues,:),1));
title('success');

currha=ha(6);
axes(currha);
plot(timespertrial,nanmean(pelletPresented_tbt(plot_cues,:),1));
title('pelletPresented');

currha=ha(7);
axes(currha);
plot(timespertrial,nanmean(drop_tbt(plot_cues,:),1));
title('drop');

currha=ha(8);
axes(currha);
plot(timespertrial,nanmean(miss_tbt(plot_cues,:),1));
title('miss');

currha=ha(9);
axes(currha);
plot(timespertrial,nanmean(reach_wout_pellet_tbt(plot_cues,:),1));
title('reach pellet absent');

currha=ha(10);
axes(currha);
plot(timespertrial,nanmean(eating_tbt(plot_cues,:),1));
title('eating');

currha=ha(11);
axes(currha);
plot(timespertrial,nanmean(pelletLoaded_tbt(plot_cues,:),1));
title('pelletLoaded');


% Also plot experiment as events in a scatter plot
cue_color='b';
% reach_color='k';
success_color='g';
drop_color='r';
drop_outline='none';
miss_color='c';
miss_outline='none';
nopellet_outline=[0.8 0.8 0.8];
nopellet_color=[0.8 0.8 0.8];
wheel_turns_color='k';
pawwheel_color='y';

event_thresh=0.2;


figure();
% for i=1:size(cue_tbt,1)
k=1;
timesOfSuccess_givenPellet=[];
timesOfReach_givenPellet=[];
timesOfReach_starts=[];
for i=plot_cues
    % Plot paw from wheel reach events
    event_ind=find(success_pawOnWheel_tbt(i,:)>event_thresh);
    for j=1:length(event_ind)
        scatter([timespertrial(event_ind(j)) timespertrial(event_ind(j))],[k k],[],'MarkerEdgeColor',success_color,...
              'MarkerFaceColor',pawwheel_color,...
              'LineWidth',1.5);
          hold on;
    end
    
    event_ind=find(drop_pawOnWheel_tbt(i,:)>event_thresh);
    for j=1:length(event_ind)
        scatter([timespertrial(event_ind(j)) timespertrial(event_ind(j))],[k k],[],'MarkerEdgeColor',drop_color,...
              'MarkerFaceColor',pawwheel_color,...
              'LineWidth',1.5);
    end
    
    event_ind=find(miss_pawOnWheel_tbt(i,:)>event_thresh);
    for j=1:length(event_ind)
        scatter([timespertrial(event_ind(j)) timespertrial(event_ind(j))],[k k],[],'MarkerEdgeColor',miss_color,...
              'MarkerFaceColor',pawwheel_color,...
              'LineWidth',1.5);
    end
    
    % Plot reach despite no pellet events
    event_ind=find(reach_wout_pellet_tbt(i,:)>event_thresh);
    for j=1:length(event_ind)
        scatter([timespertrial(event_ind(j)) timespertrial(event_ind(j))],[k k],[],'MarkerEdgeColor',nopellet_outline,...
              'MarkerFaceColor',nopellet_color,...
              'LineWidth',1.5);
    end
    % Plot cue events
    eventThresh=0.5;
    event_ind=find(cue_tbt(i,:)>event_thresh,1,'first');
%     event_ind=find(cue_tbt(i,:)>event_thresh);
    if isempty(event_ind)
        error('no cue for this trial'); 
    end
%     for j=1:length(event_ind)
%         scatter([timespertrial(event_ind(j)) timespertrial(event_ind(j))],[k k],[],cue_color,'filled');
%     end
    scatter([timespertrial(event_ind)-0.2 timespertrial(event_ind)-0.2],[k k],[],cue_color,'filled');
    hold on;
    event_thresh=0.2;
    % Plot reach start events
%     event_ind=find(reachStarts_tbt(i,:)>event_thresh);
    if excludePawOnWheelTrials==1
        timesOfReach_givenPellet=[timesOfReach_givenPellet timespertrial(reachStarts_tbt(i,:)>event_thresh & paw_from_wheel_tbt(i,:)<event_thresh & reach_pelletPresent_tbt(i,:)>event_thresh)];
    else
        timesOfReach_givenPellet=[timesOfReach_givenPellet timespertrial(reachStarts_tbt(i,:)>event_thresh & reach_pelletPresent_tbt(i,:)>event_thresh)];
    end
    timesOfReach_starts=[timesOfReach_starts timespertrial(reachStarts_tbt(i,:)>event_thresh)];
%     for j=1:length(event_ind)
%         scatter([timespertrial(event_ind(j)) timespertrial(event_ind(j))],[i i],[],reach_color,'filled');
%     end
    % Plot wheel begins to turn events
    event_thresh=0.5;
    event_ind=find(pelletPresented_tbt(i,:)>event_thresh);
    for j=1:length(event_ind)
        scatter([timespertrial(event_ind(j))-0.2 timespertrial(event_ind(j))-0.2],[k k],[],wheel_turns_color,'filled');
    end
    event_thresh=0.2;
    % Plot success events
    event_ind=find(success_tbt(i,:)>event_thresh);
    timesOfSuccess_givenPellet=[timesOfSuccess_givenPellet timespertrial(event_ind)];
    for j=1:length(event_ind)
        scatter([timespertrial(event_ind(j)) timespertrial(event_ind(j))],[k k],[],success_color,'filled');
    end
    % Plot drop events
    event_ind=find(drop_tbt(i,:)>event_thresh);
    for j=1:length(event_ind)
        scatter([timespertrial(event_ind(j)) timespertrial(event_ind(j))],[k k],[],'MarkerEdgeColor',drop_outline,...
              'MarkerFaceColor',drop_color,...
              'LineWidth',1.5);
    end
    % Plot miss events
    event_ind=find(miss_tbt(i,:)>event_thresh);
    for j=1:length(event_ind)
        scatter([timespertrial(event_ind(j)) timespertrial(event_ind(j))],[k k],[],'MarkerEdgeColor',miss_outline,...
              'MarkerFaceColor',miss_color,...
              'LineWidth',1.5);
    end
    k=k+1;
end

% Plot histogram of reach starts relative to cue
[n,x]=hist(timesOfReach_starts,100);
figure();
plot(x,n);
ma=max(n);
hold on;
temp=nanmean(cue_tbt(plot_cues,:),1);
plot(timespertrial,temp.*(ma/max(temp)),'Color','r');
title('Histogram of all reach starts');
temp=nanmean(pelletPresented_tbt(plot_cues,:),1);
plot(timespertrial,temp.*(ma/max(temp)),'Color','k');

return

% Plot probability of reach given pellet present across different trial
% time bins
pelletPresentTimes=p_pelletIsAvailable(tbt,event_thresh);
n_timebins=60;
timeOfPelletPresented=timespertrial(find(pelletPresented_tbt(1,:)>event_thresh,1,'first'));
firstNbins=floor(n_timebins*(timeOfPelletPresented/timespertrial(end)));
firstBins=linspace(0,timeOfPelletPresented,firstNbins);
timebins=[firstBins linspace(timeOfPelletPresented+(firstBins(2)-firstBins(1)),timespertrial(end),n_timebins-firstNbins)];
% Get fraction of bins in which pellet was available
pelletPresentTimes_useTrials=pelletPresentTimes(plot_cues,:);
pelletIsAvailableInBin=zeros(length(plot_cues),length(timebins)-1);
indbins=nan(1,length(timebins));
for i=1:length(timebins)-1
    [~,mi]=min(abs(timespertrial-timebins(i)));
    indbins(i)=mi;
end
indbins(end)=length(timespertrial);
for i=1:length(plot_cues)
    for j=1:length(indbins)-1
        if pelletPresentTimes_useTrials(i,indbins(j))>0.5
            % pellet is present in this bin
            pelletIsAvailableInBin(i,j)=1;
        else
            % pellet is absent in this bin
            pelletIsAvailableInBin(i,j)=0;
        end
    end
end
ntimes_pellet_available=sum(pelletIsAvailableInBin,1);
[N,edges]=histcounts(timesOfReach_givenPellet,timebins);
[N_success,edges_success]=histcounts(timesOfSuccess_givenPellet,timebins);
figure();
subplot(2,1,1);
% Plot histograms
plot(nanmean([edges(1:end-1)' edges(2:end)'],2),N,'Color','k');
hold on;
plot(timespertrial,nanmean(pelletPresented_tbt(plot_cues,:),1),'Color',[0.8 0.8 0.8]);
plot(timespertrial,nanmean(cue_tbt(plot_cues,:),1),'Color','b');
plot(nanmean([edges_success(1:end-1)' edges_success(2:end)'],2),N_success,'Color','g');
plot(nanmean([edges_success(1:end-1)' edges_success(2:end)'],2),ntimes_pellet_available,'Color','m');
% Plot # of events given pellet present, divided by # of times pellet was
% available -- this will give the fraction of times for which pellet was
% available in which mouse produced a reach
subplot(2,1,2);
temp=N./ntimes_pellet_available;
temp(N==0)=0;
plot(nanmean([edges(1:end-1)' edges(2:end)'],2),temp,'Color','k');
hold on;
temp=N_success./ntimes_pellet_available;
temp(N==0)=0;
plot(nanmean([edges(1:end-1)' edges(2:end)'],2),temp,'Color','g');
plot(timespertrial,nanmean(pelletPresented_tbt(plot_cues,:),1),'Color',[0.8 0.8 0.8]);
plot(timespertrial,nanmean(cue_tbt(plot_cues,:),1),'Color','b');
disp('done');

end


function pelletPresentTimes=p_pelletIsAvailable(tbt,event_thresh)

% tbt.cue_tbt=cue_tbt;
% tbt.distractor_tbt=distractor_tbt;
% tbt.pelletLoaded_tbt=pelletLoaded_tbt;
% tbt.pelletPresented_tbt=pelletPresented_tbt;
% tbt.reachStarts_tbt=reachStarts_tbt;
% tbt.reach_ongoing_tbt=reach_ongoing_tbt;
% tbt.success_tbt=success_tbt;
% tbt.drop_tbt=drop_tbt;
% tbt.miss_tbt=miss_tbt;
% tbt.eating_tbt=eating_tbt;
% tbt.times_tbt=times_tbt;
% tbt.movieframeinds_tbt=movieframeinds_tbt;
% tbt.reach_wout_pellet_tbt=reach_wout_pellet_tbt;
% tbt.paw_from_wheel_tbt=paw_from_wheel_tbt;
% tbt.success_pawOnWheel_tbt=success_pawOnWheel_tbt;
% tbt.drop_pawOnWheel_tbt=drop_pawOnWheel_tbt;
% tbt.miss_pawOnWheel_tbt=miss_pawOnWheel_tbt;
% tbt.reach_pelletPresent_tbt=reach_pelletPresent_tbt;

pelletPresentTimes=zeros(size(tbt.cue_tbt));
for i=1:size(tbt.pelletPresented_tbt,1)
    pelletPresentedHere=find(tbt.pelletPresented_tbt(i,:)>event_thresh);
    % If there is a reach with pellet present during or after pellet
    % presented, then pellet was actually presented
    % Else if first reach after pellet "presented" is pellet missing, then
    % there was a problem with pellet loading
    reachPelletPresent=find(tbt.reach_pelletPresent_tbt(i,:)>event_thresh);
    reachPelletMissing=find(tbt.reach_wout_pellet_tbt(i,:)>event_thresh);
    temp=reachPelletPresent>=pelletPresentedHere(1) & reachPelletPresent<pelletPresentedHere(end);
    if any(temp)
        % pellet was present on this trial
        findtemp=find(temp);
        pelletPresentTimes(i,pelletPresentedHere(1):reachPelletPresent(findtemp(1)))=1;
    elseif any(reachPelletMissing>=pelletPresentedHere(1) & reachPelletMissing<pelletPresentedHere(end))
        % pellet was absent on this trial
    else
        % assume that pellet was presented, as a default
        pelletPresentTimes(i,pelletPresentedHere(1):pelletPresentedHere(end))=1;
    end
end

end

function [cue,cueInds,cueIndITIs]=fixAliasing(cue,maxITI,minITI,bettermode)

% cue=cue*100;
cue=nonparamZscore(cue); % non-parametric Z score

[pks,locs]=findpeaks(cue);
cueInds=locs(pks>(1*10^35));
% cueInds=[1 cueInds length(cue)]; % in case aliasing problem is at edges
cueIndITIs=diff(cueInds);
checkTheseIntervals=find(cueIndITIs*bettermode>(maxITI*1.5));
for i=1:length(checkTheseIntervals)
    indsIntoCue=cueInds(checkTheseIntervals(i))+floor((maxITI/2)./bettermode):cueInds(checkTheseIntervals(i)+1)-floor((maxITI/2)./bettermode);
    if any(cue(indsIntoCue)>0.001)
        [~,ma]=max(cue(indsIntoCue)); 
        cue(indsIntoCue(ma))=max(cue);
    end
end 

[pks,locs]=findpeaks(cue);
% cueInds=locs(pks>30);
cueInds=locs(pks>(1*10^35));
cueIndITIs=diff(cueInds);
checkTheseIntervals=find(cueIndITIs*bettermode<(minITI*0.75));
if ~isempty(checkTheseIntervals)
    for i=1:length(checkTheseIntervals)
        cue(cueInds(checkTheseIntervals(i)))=0;
        cueInds(checkTheseIntervals(i))=nan; 
    end
end
cueInds=cueInds(~isnan(cueInds));
cueIndITIs=diff(cueInds);

cue=cue./nanmax(cue);

end

