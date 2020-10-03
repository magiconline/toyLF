classdef toyLF_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure               matlab.ui.Figure
        GridLayout             matlab.ui.container.GridLayout
        LeftPanel              matlab.ui.container.Panel
        apertureSliderLabel    matlab.ui.control.Label
        apertureSlider         matlab.ui.control.Slider
        focalplaneSliderLabel  matlab.ui.control.Label
        focalplaneSlider       matlab.ui.control.Slider
        cameraXSliderLabel     matlab.ui.control.Label
        cameraXSlider          matlab.ui.control.Slider
        cameraYLabel           matlab.ui.control.Label
        cameraYSlider          matlab.ui.control.Slider
        cameraZSliderLabel     matlab.ui.control.Label
        cameraZSlider          matlab.ui.control.Slider
        RightPanel             matlab.ui.container.Panel
        UIAxes                 matlab.ui.control.UIAxes
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end

    
    properties (Access = private)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%  x-y ÿÿÿÿÿÿÿÿuv-stÿÿÿÿ
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % stÿÿ
        img_width = 320;
        img_height = 240;
        imgs = zeros(16, 16, 240, 320, 3);  % 16*16=u,v  320 = s, 240 = t
        st_z = 0;
        color_chanel = 3;
        
        % uvÿÿ/ÿÿÿÿÿ
        uv_z = 1;
        aperture = 2; % ÿÿÿÿ
        
        % ÿÿÿÿ
        camera_x = 0; % xÿÿÿÿÿÿ
        camera_y = 0; % yÿÿÿÿÿÿ
        camera_z = 1;
        camera_width = 320; 
        camera_height = 240;
        focal_plane_z = 0; % ÿÿÿ
    end
    
    methods (Access = private)
        
        function img = img_show(app)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% ÿÿÿÿÿfocal planeÿÿÿÿÿÿÿÿÿÿÿ ÿÿÿÿÿÿ
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            img = zeros(app.camera_height, app.camera_width, app.color_chanel);
            
            for c_y = 1:app.camera_height
                for c_x = 1:app.camera_width
                    % ÿÿÿÿÿÿÿÿÿÿÿÿ
                    
                    % 1.ÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿf,g
                    [f,g] = app.camera_pixel_location(c_y, c_x);
                    
                    % 2.ÿÿÿÿÿÿÿÿÿÿÿÿÿÿuv-stÿÿÿÿÿÿÿ
                    % ÿÿ(camera_x, camera_y, camera_z) ÿ (f, g, focal_plane_z) ÿ z=0, z=1ÿÿ
                    % ÿÿÿ x-x1 / x2 - x1 == y-y1 / y2-y1 == z-z1 / z2-z1
                    % x1 = app.camera_x;
                    % y1 = app.camera_y;
                    % z1 = app.camera_z;
                    % x2 = f;
                    % y2 = g;
                    % z2 = app.focal_plane_z;
                    
                    % ÿz=1ÿÿÿu,v
                    t = (1 - app.camera_z)/(app.focal_plane_z-app.camera_z);
                    u = app.camera_x + (f-app.camera_x)*t;
                    v = app.camera_y + (g-app.camera_y)*t;
                    
                    % ÿz=0ÿÿÿs,t
                    t = -app.camera_z / (app.focal_plane_z-app.camera_z);
                    s = app.camera_x + (f-app.camera_x) * t;
                    t = app.camera_y + (g-app.camera_y) * t;
                    
                    
                    % 3.ÿÿu,vÿÿÿÿ aperture*aperture ÿÿÿÿÿÿÿÿu,v(ÿÿÿÿ)

                    aperture = round(app.aperture/2);
                    us = zeros(1, 4 * aperture * aperture); % 0 ÿÿÿÿÿÿÿÿÿÿÿ
                    vs = zeros(1, 4 * aperture * aperture);
                    [y, x] = app.lens_location_reverse(u, v);
                    x = floor(x);
                    y = floor(y);
                    cnt = 1;
                    for  j = y+1-aperture:y+aperture
                        for i = x+1-aperture:x+aperture
                            if (i > 0 & i <=16) & (j > 0 & j <= 16) & (sqrt((i-x)^2+(j-y)^2)<=aperture)
                                vs(cnt) = j;
                                us(cnt) = i;
                            end
                            cnt = cnt + 1;
                        end
                    end

                    % 4.ÿÿsparityÿÿs,t
                    ss = zeros(1, 4 * aperture * aperture); % ss,tsÿÿÿÿÿ
                    ts = zeros(1, 4 * aperture * aperture); % 0ÿÿÿÿÿÿÿÿÿÿÿ
                    ds = 160.5 + s - u;
                    dt = 120.5 - (t - v);

                    disparity = app.focal_plane_z / (app.focal_plane_z - 1);
                    for i = 1:length(us)
                        if us(i) ~= 0
                            ss(i) = round(ds-app.img_width*disparity*(us(i)-x));
                            ts(i) = round(dt+app.img_height*(4/3)*disparity*(vs(i)-y));    
                        end
                    end    

                    
                    % 5.ÿÿGaussianÿÿÿÿÿÿÿÿ
                    
                    % ÿÿstÿÿÿ
                    pixel = zeros(length(us), app.color_chanel);
                    for i = 1:length(ss)
                        if (ss(i) > 0 && ss(i) <= app.img_width) && (ts(i) > 0 && ts(i) <= app.img_height)
                            pixel(i, :) = reshape(app.imgs(vs(i), us(i), ts(i), ss(i), :), 1, app.color_chanel);
                        end
                    end
                    
                    % ÿÿÿÿÿÿÿÿÿÿ
                    pixel = reshape(pixel, 2*aperture, 2*aperture, app.color_chanel);
                    weight_x = normpdf(1:2*aperture, x-floor(x)+app.aperture/2, 2*app.aperture);
                    weight_y = normpdf(1:2*aperture, y-floor(y)+app.aperture/2, 2*app.aperture);
                    for c = 1:app.color_chanel
%                         pixel_h = pixel(:,:,c) * weight_x';
%                         pixel_v = weight_y * pixel_h;  
%                         img(c_y, c_x, c) = pixel_v; 
                        img(c_y, c_x, c) =  weight_y * pixel(:,:,c) * weight_x';
                    end
                end
            end

            imshow(rescale(img), 'Parent',app.UIAxes);

        end
        
        function [] = init_ui(app)
            % ÿÿÿuiÿÿ
            app.apertureSlider.Value = app.aperture; % ÿÿcamera ÿÿÿÿÿ
            app.cameraXSlider.Value = app.camera_x; % ÿÿx 
            app.cameraYSlider.Value = app.camera_y; % ÿÿy
            app.cameraZSlider.Value = app.camera_z; % ÿÿz
        end
        
        function [] = load_imgs(app)
            % ÿÿÿÿ
            img_path_list = dir('*.bmp');
            for j = 1:16
                for i=1:16
                    app.imgs(i, j, :, :, :) = rescale( ...
                        imread(string(img_path_list((i-1)*16+j).name)), ...
                        0, 1); 
                end
            end
        end

        function [f,g] = camera_pixel_location(app, c_y, c_x)
            % ÿ240*320ÿÿÿÿÿÿÿÿÿÿÿÿ
            f = app.camera_x + c_x-160.5;
            g = app.camera_y + 120.5-c_y;
        end
        
        function [i,j] = lens_location_reverse(app, u, v)
            % ÿÿÿÿÿÿÿÿÿÿÿ16*16ÿÿÿÿÿ
            i = 8.5 - v / app.img_height;
            j = u / app.img_width + 8.5;
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.init_ui(); % ÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿ
            app.load_imgs(); % ÿÿ256ÿbmpÿÿ
            app.img_show(); % ÿÿÿÿ
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {327, 327};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {199, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end

        % Value changed function: apertureSlider
        function apertureSliderValueChanged(app, event)
            % ÿÿÿÿ
            app.aperture = app.apertureSlider.Value;

            % ÿÿÿÿ
            app.img_show();
        end

        % Value changed function: focalplaneSlider
        function focalplaneSliderValueChanged(app, event)
            % ÿÿÿÿ
            app.focal_plane_z = app.focalplaneSlider.Value;

            % ÿÿÿÿ
            app.img_show();
        end

        % Value changed function: cameraXSlider
        function cameraXSliderValueChanged(app, event)
            % ÿÿÿÿx
            app.camera_x = app.cameraXSlider.Value;
            
            % ÿÿÿÿ
            app.img_show();
        end

        % Value changed function: cameraYSlider
        function cameraYSliderValueChanged(app, event)
            % ÿÿÿÿy
            app.camera_y = app.cameraYSlider.Value;
            
            % ÿÿÿÿ
            app.img_show();
        end

        % Value changed function: cameraZSlider
        function cameraZSliderValueChanged(app, event)
            % ÿÿÿÿz
            app.camera_z = app.cameraZSlider.Value;
            
            % ÿÿÿÿ
            app.img_show();
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 634 327];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.Resize = 'off';
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {199, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create apertureSliderLabel
            app.apertureSliderLabel = uilabel(app.LeftPanel);
            app.apertureSliderLabel.HorizontalAlignment = 'right';
            app.apertureSliderLabel.Position = [21 284 50 22];
            app.apertureSliderLabel.Text = 'aperture';

            % Create apertureSlider
            app.apertureSlider = uislider(app.LeftPanel);
            app.apertureSlider.Limits = [2 16];
            app.apertureSlider.MajorTicks = [2 4 6 8 10 12 14 16];
            app.apertureSlider.ValueChangedFcn = createCallbackFcn(app, @apertureSliderValueChanged, true);
            app.apertureSlider.MinorTicks = [];
            app.apertureSlider.Tooltip = {''};
            app.apertureSlider.Position = [83 304 100 3];
            app.apertureSlider.Value = 2;

            % Create focalplaneSliderLabel
            app.focalplaneSliderLabel = uilabel(app.LeftPanel);
            app.focalplaneSliderLabel.HorizontalAlignment = 'right';
            app.focalplaneSliderLabel.Position = [9 233 64 22];
            app.focalplaneSliderLabel.Text = 'focal plane';

            % Create focalplaneSlider
            app.focalplaneSlider = uislider(app.LeftPanel);
            app.focalplaneSlider.Limits = [0.01 0.03];
            app.focalplaneSlider.ValueChangedFcn = createCallbackFcn(app, @focalplaneSliderValueChanged, true);
            app.focalplaneSlider.MinorTicks = [];
            app.focalplaneSlider.Position = [83 254 100 3];
            app.focalplaneSlider.Value = 0.03;

            % Create cameraXSliderLabel
            app.cameraXSliderLabel = uilabel(app.LeftPanel);
            app.cameraXSliderLabel.HorizontalAlignment = 'right';
            app.cameraXSliderLabel.Position = [11 185 57 22];
            app.cameraXSliderLabel.Text = 'camera X';

            % Create cameraXSlider
            app.cameraXSlider = uislider(app.LeftPanel);
            app.cameraXSlider.Limits = [-2000 2000];
            app.cameraXSlider.ValueChangedFcn = createCallbackFcn(app, @cameraXSliderValueChanged, true);
            app.cameraXSlider.MinorTicks = [];
            app.cameraXSlider.Position = [85 204 100 3];

            % Create cameraYLabel
            app.cameraYLabel = uilabel(app.LeftPanel);
            app.cameraYLabel.HorizontalAlignment = 'right';
            app.cameraYLabel.Position = [12 135 57 22];
            app.cameraYLabel.Text = 'camera Y';

            % Create cameraYSlider
            app.cameraYSlider = uislider(app.LeftPanel);
            app.cameraYSlider.Limits = [-1500 1500];
            app.cameraYSlider.MajorTicks = [-1500 0 1500];
            app.cameraYSlider.ValueChangedFcn = createCallbackFcn(app, @cameraYSliderValueChanged, true);
            app.cameraYSlider.MinorTicks = [];
            app.cameraYSlider.Position = [85 154 100 3];

            % Create cameraZSliderLabel
            app.cameraZSliderLabel = uilabel(app.LeftPanel);
            app.cameraZSliderLabel.HorizontalAlignment = 'right';
            app.cameraZSliderLabel.Position = [21 85 56 22];
            app.cameraZSliderLabel.Text = 'camera Z';

            % Create cameraZSlider
            app.cameraZSlider = uislider(app.LeftPanel);
            app.cameraZSlider.Limits = [0 3];
            app.cameraZSlider.ValueChangedFcn = createCallbackFcn(app, @cameraZSliderValueChanged, true);
            app.cameraZSlider.MinorTicks = [];
            app.cameraZSlider.Position = [89 104 100 3];
            app.cameraZSlider.Value = 1;

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            % Create UIAxes
            app.UIAxes = uiaxes(app.RightPanel);
            title(app.UIAxes, '')
            xlabel(app.UIAxes, '')
            ylabel(app.UIAxes, '')
            app.UIAxes.XTick = [];
            app.UIAxes.YTick = [];
            app.UIAxes.TitleFontWeight = 'bold';
            app.UIAxes.Position = [18 13 400 300];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = toyLF_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

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