function out=parseSerialOut_wrapper(filename,outfile)

% Deal with cases where experimenter unplugged Arduino part-way through
% session

% Break serial out file into time-continuous segments
nPartFile=breakFileIntoTimeChunks(filename);

% Parse each file segment
endoffname=regexp(filename,'.txt');
outParts=cell(1,nPartFile);
for i=1:nPartFile
    outParts{i}=parseSerialOut([filename(1:endoffname-1) '_part' num2str(i) '.txt'],outfile);
end

% Concatenate outputs
f=fieldnames(outParts{1});
for i=1:length(f)
    out.(f{i})=[];
end
for i=1:nPartFile
    temp=outParts{i};
    for j=1:length(f)    
        out.(f{j})=concatField(out.(f{j}),temp.(f{j}));
    end
end

% Check that allTrialTimes are a monotonically increasing function, even
% after concatenating multiple sections of OUTPUT.txt
for i=2:size(out.allTrialTimes,1)
    if min(out.allTrialTimes(i,:))<max(out.allTrialTimes(i-1,:))
        % Time goes backward
        % Fix this
        out.allTrialTimes(i:end,:)=out.allTrialTimes(i:end,:)-min(out.allTrialTimes(i,:))+1+max(out.allTrialTimes(i-1,:));
    end
end

% Save data
save(outfile,'out');

end

function out=concatField(data1, data2)

if (size(data2,1)==1) & (size(data2,2)==1) & (size(data1,1)==1) & (size(data1,2)==1)
    out=[data1 data2];
elseif (size(data2,1)==1) & (size(data2,2)>1) & (size(data1,1)==1)
    % 1D data
    out=[data1 data2];
elseif (size(data2,1)>1) & (size(data2,2)==1) & (size(data1,2)==1)
    % 1D data
    out=[data1; data2];
else
    % 2D data
    % Pad data with nans if one is longer
    if size(data2,2)>size(data1,2)
        % Pad data1
        data1=[data1 nan(size(data1,1), size(data2,2)-size(data1,2))];
    else
        % Pad data2
        data2=[data2 nan(size(data2,1), size(data1,2)-size(data2,2))];
    end
    out=[data1; data2];
end

end

function currPart=breakFileIntoTimeChunks(filename)

% Open file to read
fid=fopen(filename);

% Open file to write
currPart=1;
endoffname=regexp(filename,'.txt');
fidOut=fopen([filename(1:endoffname-1) '_part' num2str(currPart) '.txt'],'w');

eventTime=nan;
previousEventTime=nan;
cline=fgetl(fid);
while cline~=-1
    % is -1 at eof
    % parse
    breakInds=regexp(cline,'>');
    if isempty(breakInds) || strcmp(cline,'skip')
        % discard this line
        cline=fgetl(fid);
        if isempty(cline)
            cline='\r\n';
        end
        continue
    elseif length(breakInds)==1
        % format of this line is eventWriteCode then eventInfo
        eventWriteCode=str2double(cline(1:breakInds(1)-1));
        eventInfo=str2double(cline(breakInds(1)+1:end));
    elseif length(breakInds)==2
        % format of this line is eventWriteCode, eventInfo, then eventTime
        eventWriteCode=str2double(cline(1:breakInds(1)-1));
        eventInfo=cline(breakInds(1)+1:breakInds(2)-1);
        eventTime=single(str2double(cline(breakInds(2)+1:end)));
    else
        % problem
        error('improperly formatted line');
    end
    if isnan(previousEventTime)
    else
        if eventTime<previousEventTime
            % Time break
            % Break file here
            fclose(fidOut);
            currPart=currPart+1;
            fidOut=fopen([filename(1:endoffname-1) '_part' num2str(currPart) '.txt'],'w');
        end
    end
    fprintf(fidOut,[cline '\r\n']);
    previousEventTime=eventTime;
    cline=fgetl(fid);
    if isempty(cline)
        cline='\r\n';
    end
end

fclose(fidOut);
fclose(fid);

end