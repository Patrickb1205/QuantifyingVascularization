classdef QuantifyingVascularization < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                 matlab.ui.Figure
        TabGroup                 matlab.ui.container.TabGroup
        AnalyzeTab               matlab.ui.container.Tab
        Panel                    matlab.ui.container.Panel
        ComplexROIButtonGroup    matlab.ui.container.ButtonGroup
        SelectOuterROIButton     matlab.ui.control.Button
        SelectInnerROIButton     matlab.ui.control.Button
        SimpleROIButtonGroup     matlab.ui.container.ButtonGroup
        SelectROIButton          matlab.ui.control.Button
        AnalyzeImageButton       matlab.ui.control.Button
        MeasurementsButtonGroup  matlab.ui.container.ButtonGroup
        RemoveBackgroundButton   matlab.ui.control.Button
        MeanIntensityButton      matlab.ui.control.RadioButton
        ImageToolsButtonGroup    matlab.ui.container.ButtonGroup
        ImportImagesButton       matlab.ui.control.Button
        UIAxes                   matlab.ui.control.UIAxes
        DataTab                  matlab.ui.container.Tab
        ExportasExcelButton      matlab.ui.control.Button
        UITable                  matlab.ui.control.Table
    end

    properties (Access = private)
    ImageFileNames % Names of the selected image files
    ImageFilePath  % Path to the selected image files
    CurrentImage   % Currently displayed image
    CurrentROIs % Current ROI drawn on the image
    CurrentImageIndex = 1 % Index of the current image being displayed 
    AllImageROIs % Cell array to store ROIs for all images 
    ROIResults % Structure to store ROI analysis results
    OuterROI % Variable for Outer ROI
    InnerROIs % Variable for Inner ROIs 
    BackgroundRemoved %checks for removal
    BinarizedImage %storesbinarizedimage
    % Assuming 'app.UIAxes' is the name of your axes component
   
    
    end

    
    
    methods (Access = private)

    
        
    function updateResultsTable(app)
    data = {};
rowIndex = 1;
for i = 1:length(app.ROIResults)
    imageName = app.ROIResults(i).ImageName;
    for j = 1:length(app.ROIResults(i).ROIs)
        meanIntensity = app.ROIResults(i).ROIs(j).MeanIntensity;
        data{rowIndex, 1} = imageName;  % Image name
        data{rowIndex, 2} = j;          % ROI number
        data{rowIndex, 3} = meanIntensity;  % Mean intensity
        rowIndex = rowIndex + 1;
    end
end
app.UITable.Data = data;
app.UITable.ColumnName = {'Image Name', 'ROI Number', 'Mean Intensity'};


    end

    

    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn2(app)
     opengl hardware
     opengl('save', 'hardware')

            set(app.UIFigure, 'Renderer', 'opengl');   
            % Example: Hide axes on startup
    app.UIAxes.XAxis.Visible = 'off';
    app.UIAxes.YAxis.Visible = 'off';
    % Assuming 'app.UIAxes' is your axes component
    xlabel(app.UIAxes, '');  % Remove X-axis label
    ylabel(app.UIAxes, '');  % Remove Y-axis label
    title(app.UIAxes, '');   % Remove the title
    
   
        end

        % Callback function: ImageToolsButtonGroup, ImportImagesButton
        function ImageToolsButtonGroupButtonDown(app, event)
          % Callback function for ImportImagesButton_2
    % Open file dialog for user to select images
    [fileNames, filePath] = uigetfile({'*.png;*.jpg','PNG/JPG Images'}, ...
                                      'Select Images', 'MultiSelect', 'on');
    
    % Check if the user selected any file
    if isequal(fileNames, 0)
        disp('User selected Cancel');
        return;
    end

    % Ensure fileNames is a cell array, even for a single file
    if ~iscell(fileNames)
        fileNames = {fileNames};
    end

    % Store file names and path in the app properties
    app.ImageFileNames = fileNames;
    app.ImageFilePath = filePath;

    app.ROIResults = struct('ImageName',{},'ROIs',{},'MeanIntensity',{});

    % Load and display the first image
    firstImage = imread(fullfile(filePath, fileNames{1}));
    imagesc(app.UIAxes, firstImage); % Display the image in the app's axes
    axis(app.UIAxes, 'image'); % Adjust the axes for image display
    colormap(app.UIAxes, gray); % Set colormap if needed

    % Store the first image for further analysis
    app.CurrentImage = firstImage;

    % ... add any additional code for setup after image import ...

  
        end

        % Button pushed function: SelectROIButton
        function SelectROIButtonPushed(app, event)
   

            % Callback function for DrawROIButton
    % Check if there is an image loaded
    if isempty(app.CurrentImage)
        uialert(app.UIFigure, 'No image loaded.', 'Load Image First');
        return;
    end
    newROI = drawpolygon(app.UIAxes);
    % User can draw a rectangle as ROI on the image
    app.CurrentROIs{end+1} = newROI; 

    % Optional: add code here to handle the ROI, like extracting
    % the region, performing calculations, etc.

        end

        % Button pushed function: AnalyzeImageButton
        function AnalyzeImageButtonPushed(app, event)
   
            % Callback function for AnalyzeImageButton
            % Check if there is an image and ROI selected
            if isempty(app.CurrentImage) || isempty(app.CurrentROIs) && isempty(app.OuterROI)
                uialert(app.UIFigure, 'No image or ROI selected.', 'Error');
                return;
            end

            currentImageResults = struct('ROIs',{},'MeanIntensity',{});
            app.ROIResults(app.CurrentImageIndex).ImageName = app.ImageFileNames{app.CurrentImageIndex};
            
            % Use the binarized image if background was removed
            if app.BackgroundRemoved
                img_to_use = app.BinarizedImage;
            else
                img_gray = rgb2gray(app.CurrentImage);
                level = graythresh(img_gray);
                img_to_use = imbinarize(img_gray, level);
            end

            % Analyze each ROI
            for i = 1:length(app.CurrentROIs)
                mask = createMask(app.CurrentROIs{i}, img_to_use);
                bin_roi_otsu = uint8(double(img_to_use) .* mask);
                meanIntensity_otsu = sum(bin_roi_otsu(mask == 1)) / sum(mask(:) == 1) * 255;
                
                % Store results for the current image
                app.ROIResults(app.CurrentImageIndex).ROIs(i).Position = app.CurrentROIs{i}.Position;
                app.ROIResults(app.CurrentImageIndex).ROIs(i).MeanIntensity = meanIntensity_otsu;
                % Display the results or store them as needed
                fprintf('ROI %d - Mean Intensity: %f\n', i, meanIntensity_otsu);
            end
      
    
    if ~isempty(app.OuterROI)
        img_gray = rgb2gray(app.CurrentImage);
        level = graythresh(img_gray);
        bin_img = imbinarize(img_gray,level);
        outerMask = createMask(app.OuterROI, bin_img);
        for j = 1:length(app.InnerROIs)
            innerMask = createMask(app.InnerROIs{j}, bin_img);
            outerMask(innerMask) = false;
        end
        bin_roi_otsu = uint8(double(bin_img) .* outerMask);
        meanIntensity = sum(bin_roi_otsu(outerMask == 1)) / sum(outerMask(:) == 1) * 255;
        complexIndex = length(app.CurrentROIs)+1;
        app.ROIResults(app.CurrentImageIndex).ROIs(complexIndex).MeanIntensity = meanIntensity;
    end


    % Load the next image (if available)
    app.CurrentImageIndex = app.CurrentImageIndex + 1;
    if app.CurrentImageIndex <= numel(app.ImageFileNames)
        nextImage = imread(fullfile(app.ImageFilePath, app.ImageFileNames{app.CurrentImageIndex}));
        imagesc(app.UIAxes, nextImage);
        axis(app.UIAxes, 'image');
        app.CurrentImage = nextImage;
        app.CurrentROIs = {}; % Reset ROI for the next image
        app.InnerROIs = {};
        app.OuterROI = [];
    else
    
     for i = 1:length(app.ROIResults)
    fprintf('Image: %s\n', app.ROIResults(i).ImageName)
    for j = 1:length(app.ROIResults(i).ROIs)
        fprintf('  ROI %d - Mean Intensity: %f\n', j, app.ROIResults(i).ROIs(j).MeanIntensity)
    end
    end
        uialert(app.UIFigure, 'No more images to load.', 'Done');
        updateResultsTable(app);
        % Example: Accessing stored results


    end

    


   
        end

        % Button pushed function: SelectInnerROIButton
        function SelectInnerROIButtonPushed(app, event)
           % Draw the ROI with deferred updates
    newInnerROI = drawpolygon(app.UIAxes);
    app.InnerROIs{end+1} = newInnerROI;
        end

        % Button pushed function: SelectOuterROIButton
        function SelectOuterROIButtonPushed(app, event)
           % Draw the ROI with deferred updates
    newOuterROI = drawpolygon(app.UIAxes);
    app.OuterROI = newOuterROI; 
        end

        % Button pushed function: ExportasExcelButton
        function ExportasExcelButtonPushed(app, event)
        
    [file, path] = uiputfile('*.xlsx', 'Save file');
    if isequal(file, 0)
        disp('User clicked Cancel.');
        return;
    end
    filename = fullfile(path, file);

    % Cross-verify the number of columns in data with column names
    numDataColumns = size(app.UITable.Data, 2);
    if numDataColumns ~= length(app.UITable.ColumnName)
        % Correct the column names to match the data
        correctedColumnNames = arrayfun(@(x) ['Column' num2str(x)], 1:numDataColumns, 'UniformOutput', false);
        app.UITable.ColumnName = correctedColumnNames;
    end

    % Export the table
    T = cell2table(app.UITable.Data, 'VariableNames', app.UITable.ColumnName);
    writetable(T, filename, 'Sheet', 1);
    disp(['Results table saved to ', filename]);

        end

        % Button pushed function: RemoveBackgroundButton
        function RemoveBackgroundButtonPushed(app, event)
             
            % Check if there is an image loaded
            if isempty(app.CurrentImage)
                uialert(app.UIFigure, 'No image loaded.', 'Load Image First');
                return;
            end
            
            % Convert the image to grayscale
            img_gray = rgb2gray(app.CurrentImage);
            
            % Prompt user to make a rectangular selection
            h1 = drawrectangle(app.UIAxes);
            mask1 = createMask(h1, img_gray);

            mean_pix = mean(img_gray(mask1));
            std_mean = std2(img_gray(mask1));
            
            % Create binary mask for background removal
            level_bin = graythresh(img_gray);
            bin_img7 = imbinarize(img_gray, level_bin);
            app.BinarizedImage = bin_img7 & (img_gray > (mean_pix + 2 * std_mean));
            
            % Update the flag for background removal
            app.BackgroundRemoved = true;
         
        
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1174 732];
            app.UIFigure.Name = 'MATLAB App';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [10 14 1151 711];

            % Create AnalyzeTab
            app.AnalyzeTab = uitab(app.TabGroup);
            app.AnalyzeTab.Title = 'Analyze';

            % Create UIAxes
            app.UIAxes = uiaxes(app.AnalyzeTab);
            title(app.UIAxes, 'Title')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Position = [240 44 881 601];

            % Create Panel
            app.Panel = uipanel(app.AnalyzeTab);
            app.Panel.Position = [17 1 196 657];

            % Create ImageToolsButtonGroup
            app.ImageToolsButtonGroup = uibuttongroup(app.Panel);
            app.ImageToolsButtonGroup.Title = '       Image Tools';
            app.ImageToolsButtonGroup.ButtonDownFcn = createCallbackFcn(app, @ImageToolsButtonGroupButtonDown, true);
            app.ImageToolsButtonGroup.FontSize = 16;
            app.ImageToolsButtonGroup.Position = [13 483 168 87];

            % Create ImportImagesButton
            app.ImportImagesButton = uibutton(app.ImageToolsButtonGroup, 'push');
            app.ImportImagesButton.ButtonPushedFcn = createCallbackFcn(app, @ImageToolsButtonGroupButtonDown, true);
            app.ImportImagesButton.Position = [23 13 121 35];
            app.ImportImagesButton.Text = 'Import Images';

            % Create MeasurementsButtonGroup
            app.MeasurementsButtonGroup = uibuttongroup(app.Panel);
            app.MeasurementsButtonGroup.TitlePosition = 'centertop';
            app.MeasurementsButtonGroup.Title = 'Measurements';
            app.MeasurementsButtonGroup.FontSize = 16;
            app.MeasurementsButtonGroup.Position = [15 338 167 123];

            % Create MeanIntensityButton
            app.MeanIntensityButton = uiradiobutton(app.MeasurementsButtonGroup);
            app.MeanIntensityButton.Text = 'Mean Intensity';
            app.MeanIntensityButton.FontSize = 14;
            app.MeanIntensityButton.Position = [25 15 113 22];
            app.MeanIntensityButton.Value = true;

            % Create RemoveBackgroundButton
            app.RemoveBackgroundButton = uibutton(app.MeasurementsButtonGroup, 'push');
            app.RemoveBackgroundButton.ButtonPushedFcn = createCallbackFcn(app, @RemoveBackgroundButtonPushed, true);
            app.RemoveBackgroundButton.Position = [16 54 136 27];
            app.RemoveBackgroundButton.Text = 'Remove Background';

            % Create AnalyzeImageButton
            app.AnalyzeImageButton = uibutton(app.Panel, 'push');
            app.AnalyzeImageButton.ButtonPushedFcn = createCallbackFcn(app, @AnalyzeImageButtonPushed, true);
            app.AnalyzeImageButton.Position = [14 584 168 55];
            app.AnalyzeImageButton.Text = 'Analyze Image';

            % Create SimpleROIButtonGroup
            app.SimpleROIButtonGroup = uibuttongroup(app.Panel);
            app.SimpleROIButtonGroup.TitlePosition = 'centertop';
            app.SimpleROIButtonGroup.Title = 'Simple ROI';
            app.SimpleROIButtonGroup.FontSize = 16;
            app.SimpleROIButtonGroup.Position = [15 226 167 94];

            % Create SelectROIButton
            app.SelectROIButton = uibutton(app.SimpleROIButtonGroup, 'push');
            app.SelectROIButton.ButtonPushedFcn = createCallbackFcn(app, @SelectROIButtonPushed, true);
            app.SelectROIButton.Position = [22 19 120 29];
            app.SelectROIButton.Text = 'Select ROI';

            % Create ComplexROIButtonGroup
            app.ComplexROIButtonGroup = uibuttongroup(app.Panel);
            app.ComplexROIButtonGroup.TitlePosition = 'centertop';
            app.ComplexROIButtonGroup.Title = 'Complex ROI';
            app.ComplexROIButtonGroup.FontSize = 16;
            app.ComplexROIButtonGroup.Position = [13 57 167 148];

            % Create SelectInnerROIButton
            app.SelectInnerROIButton = uibutton(app.ComplexROIButtonGroup, 'push');
            app.SelectInnerROIButton.ButtonPushedFcn = createCallbackFcn(app, @SelectInnerROIButtonPushed, true);
            app.SelectInnerROIButton.Position = [19 69 128 31];
            app.SelectInnerROIButton.Text = 'Select Inner ROI';

            % Create SelectOuterROIButton
            app.SelectOuterROIButton = uibutton(app.ComplexROIButtonGroup, 'push');
            app.SelectOuterROIButton.ButtonPushedFcn = createCallbackFcn(app, @SelectOuterROIButtonPushed, true);
            app.SelectOuterROIButton.Position = [17 25 130 28];
            app.SelectOuterROIButton.Text = 'Select Outer ROI';

            % Create DataTab
            app.DataTab = uitab(app.TabGroup);
            app.DataTab.Title = 'Data';

            % Create UITable
            app.UITable = uitable(app.DataTab);
            app.UITable.ColumnName = {'Column 1'; 'Column 2'; 'Column 3'; 'Column 4'};
            app.UITable.RowName = {};
            app.UITable.Position = [74 19 1058 617];

            % Create ExportasExcelButton
            app.ExportasExcelButton = uibutton(app.DataTab, 'push');
            app.ExportasExcelButton.ButtonPushedFcn = createCallbackFcn(app, @ExportasExcelButtonPushed, true);
            app.ExportasExcelButton.Position = [17 644 108 26];
            app.ExportasExcelButton.Text = 'Export as Excel';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = QuantifyingVascularization

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn2)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end