%TDMS editor
%1.0
%Dominik Schneidereit
%dominik.schneidereit@fau.de

%based on TDMSCutter of Jonas Ahr

global indicatorPlot;
global plot1;
global plot2;
global displayFigure;
global mainWindow;
global tdmsData;
global newTdmsData;
global functionButtonList;
global loadFilePath;
titleString = 'TDMS editor v0.1';

disp(titleString);
disp('Institute of Medical Biotechnology, FAU Erlangen');
disp('loading GUI...');

mainWindow = uifigure;

displayFigure = figure;
yyaxis left;
xlabel('Time (s)');
ylabel('Force (mN)');
yyaxis right;
ylabel('Position (µm)');

displayFigure.CloseRequestFcn = @(src, event)mainWindowClose_callback(src);
%this functionality is depreceated
%set(displayFigure,"WindowButtonDownFcn", @figureWindowClickCallback);
displayFigure.NumberTitle = 'off';
displayFigure.Name = titleString;

windowHeight = 200;
windowWidth = 180;
spacer = 20;
buttonWidth = 140;

mainWindow.Position = [256 256 windowWidth windowHeight];
mainWindow.Name = "";
mainWindow.NumberTitle = 'off';
mainWindow.ToolBar = 'none';
mainWindow.MenuBar = 'none';
mainWindow.Resize = 'off';

mainWindow.CloseRequestFcn = @(src, event)mainWindowClose_callback(src);

buttonLoad = uibutton(mainWindow, 'ButtonPushedFcn',@loadButton_callback);
buttonLoad.Text = "Load TDMS File";
buttonLoad.Position = [spacer windowHeight-(2*spacer) buttonWidth spacer];

buttonTruncate = uibutton(mainWindow, 'ButtonPushedFcn',@truncateButton_callback);
buttonTruncate.Text = "Truncate TDMS File";
buttonTruncate.Position = [spacer windowHeight-(4*spacer) buttonWidth spacer];

buttonAppend = uibutton(mainWindow, 'ButtonPushedFcn',@appendButton_callback);
buttonAppend.Text = "Append a TDMS File";
buttonAppend.Position = [spacer windowHeight-(6*spacer) buttonWidth spacer];

buttonSave = uibutton(mainWindow, 'ButtonPushedFcn',@saveButton_callback);
buttonSave.Text = "Save results to file";
buttonSave.Position = [spacer windowHeight-(8*spacer) buttonWidth spacer];

functionButtonList = [buttonTruncate, buttonAppend, buttonSave];

for i = 1:length(functionButtonList)
    functionButtonList(i).Enable = 'off';
end

%end of main loop, start of function space

function tdmsData = readTdmsFileToArrays(targetFile)
tdmsData = tdmsread(targetFile);
return
end

function updateGraph(tdmsData)
global plot1;
global plot2;
disp("updating Graph...")
clf;
%extract data from tdms-file for the graph

ttData = tdmsData{1};
ttData2 = tdmsData{2};

xTime = ttData{:, 1};
y1Force = ttData{:, 2};
y2Stretch = ttData2{:, 2};

% plot Graphs

hold on;
yyaxis left;

plot1=plot(xTime, y1Force, 'LineWidth', 2.0);
yyaxis right;

plot2=plot(xTime, y2Stretch, 'LineWidth', 2.0);
grid on
hold off;

disp("done updating Graph")
end

function saveButton_callback(src,event)
global loadFilePath;
global tdmsData;
[fileName, filePath] = uiputfile([loadFilePath 'ModifiedFile.tdms'],"Define a save file name and location");
targetFile = [filePath fileName];
if ischar(fileName)
    disp(['Saving ' fileName '...']);
    tdmswrite(targetFile, tdmsData);
    disp('Done');
end
end


function appendButton_callback(src, event)
global loadFilePath;
global tdmsData;
[fileName, filePath] = uigetfile('*.tdms',"Select a TDMS file", loadFilePath,"MultiSelect","off");
loadFilePath = filePath;
targetFile = [filePath fileName];

if ischar(fileName)
    appendSideStrg = questdlg('Do you want to append at the front or the end of the current data set?','Choose side to append to', 'Front', 'Rear', 'Rear');

    if ~isempty(appendSideStrg)
        gapSizeStr = inputdlg('Gap size (s):', 'Leave a Gap in between the data sets?',[1,45],"0");

        gapSize = 0;
        if ~isempty(gapSizeStr)
            gapSize = str2double(gapSizeStr);
        end

        disp(['loading ' fileName '...'])
        toAppendTdmsData = tdmsread(targetFile);

        disp(['appending data sets...'])

        switch appendSideStrg
            case 'Front'
                timeShift = toAppendTdmsData{1}{end,1}; %get the last entry in the time trace of channel

                for i=1:length(tdmsData)
                    tdmsData{i}.(1) = tdmsData{i}.(1) + timeShift+ gapSize; % add the time to each time trace of each channel of the data that needs appending
                    tdmsData{i} = [toAppendTdmsData{i};tdmsData{i}]; %append the time shifted original data to the end of the new data
                    %tdmsTest{2} = [tdmsTest{2};tdmsTest2{2}]
                end

            case 'Rear'
                timeShift = tdmsData{1}{end,1}; %get the last entry in the time trace of channel 1

                for i=1:length(toAppendTdmsData)
                    toAppendTdmsData{i}.(1) = toAppendTdmsData{i}.(1) + timeShift+ gapSize; % add the time to each time trace of each channel of the data that needs appending
                    tdmsData{i} = [tdmsData{i};toAppendTdmsData{i}]; %append time shifted data to the end of existing data
                    %tdmsTest{2} = [tdmsTest{2};tdmsTest2{2}]
                end
        end
        updateGraph(tdmsData);
    end
end
end

function truncateButton_callback(src, event)
global tdmsData;
global newTdmsData;
table1 = tdmsData{1};
table2 = tdmsData{2};
timeLine = table1{:,1};
timeStart = timeLine(1);
timeEnd = timeLine(end);
displayString = timeStart+"-"+timeEnd;
%disp(displayString);

prompts = {'New start time (s):', 'New end time (s):'};
defInputs = {num2str(timeStart), num2str(timeEnd)};
newRangeStr = inputdlg(prompts, "Define a new time interval",[1,45;1,45],defInputs);

if ~isempty(newRangeStr)
    newRange = str2double(newRangeStr);
    indexesOfRelevantData = find(timeLine>=newRange(1)&timeLine<=newRange(2));
    tdmsData = [{table1(indexesOfRelevantData,:)},{table2(indexesOfRelevantData,:)}];
    updateGraph(tdmsData);
end

end

function loadButton_callback(src,event)
global tdmsData;
global functionButtonList;
global loadFilePath;

[fileName, filePath] = uigetfile('*.tdms',"Select a TDMS file", "E:\DATEN\Projekte\2022_MarfanAortaWagner_Schneidereit\03 RawData","MultiSelect","off");
loadFilePath = filePath;
targetFile = [filePath fileName];

if ischar(fileName)
    disp(['loading ' fileName '...'])
    tdmsData = readTdmsFileToArrays(targetFile);
    updateGraph(tdmsData);

    for i = 1:length(functionButtonList)
        functionButtonList(i).Enable = 'on';
    end
end

end

function mainWindowClose_callback(src, event)
global displayFigure
global mainWindow

delete(displayFigure);
delete(mainWindow);
end

%depreceated
function figureWindowClickCallback(src, event)
global indicatorPlot;
src
event
hold on

pos = src.CurrentAxes.CurrentPoint;
disp([pos(1,1),pos(1,2)]);
indicatorPlot = plot(pos(1,1),pos(1,2),"Marker","o");

hold off
end