classdef app1_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                    matlab.ui.Figure
        Lamp                        matlab.ui.control.Lamp
        LampLabel                   matlab.ui.control.Label
        CutFrequencyEditField       matlab.ui.control.NumericEditField
        CutFrequencyEditFieldLabel  matlab.ui.control.Label
        FilterTypeDropDown          matlab.ui.control.DropDown
        FilterTypeDropDownLabel     matlab.ui.control.Label
        StartStopButton             matlab.ui.control.Button
        UIAxesFilteredSpectrum      matlab.ui.control.UIAxes
        UIAxesFilteredSignal        matlab.ui.control.UIAxes
        UIAxesRawSpectrum           matlab.ui.control.UIAxes
        UIAxesRawSignal             matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
      s                       % Serial port object
        numPoints = 100;        % Number of data points to display
        rawData                 % Raw data buffer
        filteredData            % Filtered data buffer
        time                    % Time vector
        filterCoeff             % Filter coefficients
        voltageRange = 500;     % Voltage range of your analog sensor
        filterOrder = 5;        % Filter order
        isRunning = false;  
         filterCutoffFrequency = 10;
         % Flag to check if data acquisition is running
    end
    
    methods (Access = private)
        
     function updateCutoffFrequency(app, ~, ~)
            app.filterCutoffFrequency = app.CutFrequencyEditField.Value;
            % Update filter coefficients based on the selected filter type and cutoff frequency
            selectedFilter = app.FilterTypeDropDown.Value;
            switch selectedFilter
                case 'lowpass'
                    app.filterCoeff = designfilt('lowpassiir', ...
                        'FilterOrder', app.filterOrder, ...
                        'PassbandFrequency', app.filterCutoffFrequency, ...
                        'PassbandRipple', 0.2, ...
                        'SampleRate', 1000);
                case 'highpass'
                    app.filterCoeff = designfilt('highpassiir', ...
                        'FilterOrder', app.filterOrder, ...
                        'PassbandFrequency', app.filterCutoffFrequency, ...
                        'PassbandRipple', 0.2, ...
                        'SampleRate', 1000);
            end
        end

        function startDataAcquisition(app)
            % Create a new serialport object and specify the COM port
            app.s = serialport('COM9', 115200);

            % Open the serial connection
            configureTerminator(app.s, "LF");
            fopen(app.s);

            % Initialize data vectors
            app.rawData = zeros(1, app.numPoints);
            app.filteredData = zeros(1, app.numPoints);
            app.time = 1:app.numPoints;

            % Set up the plot limits
            xlim(app.UIAxesRawSignal, [0, app.numPoints]);
            ylim(app.UIAxesRawSignal, [-app.voltageRange, app.voltageRange]);

            xlim(app.UIAxesFilteredSignal, [0, app.numPoints]);
            ylim(app.UIAxesFilteredSignal, [-app.voltageRange, app.voltageRange]);

            % Update filter coefficients
            app.updateCutoffFrequency();

            % Update flag
            app.isRunning = true;

            while ishandle(app.UIAxesRawSignal) && app.isRunning
                % Read data from the Arduino
                newData = str2double(fgetl(app.s));
                newData = newData - 150;

                % Update the data vectors
                app.rawData = [app.rawData(2:end), newData];

                % Apply the filter
                app.filteredData = filter(app.filterCoeff, app.rawData);

                % Update the Raw signal and filtered signal time-domain plots
                plot(app.UIAxesRawSignal, app.time, app.rawData, 'b', 'LineWidth', 1.5);
                plot(app.UIAxesFilteredSignal, app.time, app.filteredData, 'r', 'LineWidth', 1.5);
                spectrumRaw = fft(app.rawData);
    frequencyRaw = linspace(0, 1, app.numPoints) * (1 / (2 * (1 / 115200))); % Adjust for your sampling rate
    frequencyRawKHz = frequencyRaw / 1000;
    amplitudeRaw = abs(spectrumRaw) / app.numPoints;
    plot(app.UIAxesRawSpectrum, frequencyRawKHz, amplitudeRaw);
    title(app.UIAxesRawSpectrum, 'Amplitude vs Frequency');
    xlabel(app.UIAxesRawSpectrum, 'Frequency (kHz)');
    ylabel(app.UIAxesRawSpectrum, 'Amplitude');

    % Update the Filtered signal frequency spectrum
    spectrumFiltered = fft(app.filteredData);
    amplitudeFiltered = abs(spectrumFiltered) / app.numPoints;
    plot(app.UIAxesFilteredSpectrum, frequencyRawKHz, amplitudeFiltered);
    title(app.UIAxesFilteredSpectrum, 'Amplitude vs Frequency');
    xlabel(app.UIAxesFilteredSpectrum, 'Frequency (kHz)');
    ylabel(app.UIAxesFilteredSpectrum, 'Amplitude');

                drawnow;

                pause(0.005);  % Adjust the pause duration as needed
            end
        end


        % Function to stop data acquisition
        function stopDataAcquisition(app)
               % Update flag
            app.isRunning = false;

            % Close the serial connection when done
            fclose(app.s);
            delete(app.s);
            clear app.s;
        end
    end
        
   
       
        % Code that executes before app deletion
       
  

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
           
        end

        % Button down function: UIAxesRawSignal
        function UIAxesRawSignalButtonDown(app, event)
            
        end

        % Button pushed function: StartStopButton
        function StartStopButtonPushed(app, event)
         if app.isRunning
                % If already running, stop data acquisition
                app.stopDataAcquisition();
            else
                % If not running, start data acquisition
                app.startDataAcquisition();
         end
        

        end

        % Button down function: UIAxesRawSpectrum
        function UIAxesRawSpectrumButtonDown(app, event)
            
        end

        % Button down function: UIAxesFilteredSignal
        function UIAxesFilteredSignalButtonDown(app, event)
            
        end

        % Button down function: UIAxesFilteredSpectrum
        function UIAxesFilteredSpectrumButtonDown(app, event)
            
        end

        % Drop down opening function: FilterTypeDropDown
        function FilterTypeDropDownOpening(app, event)
      
                
        end

        % Value changed function: CutFrequencyEditField
        function CutFrequencyEditFieldValueChanged(app, event)
           
           if app.CutFrequencyEditField.Value==0
               
            app.CutFrequencyEditField.Value=350;
            
           end
            
            updateCutoffFrequency(app);
           
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 968 749];
            app.UIFigure.Name = 'MATLAB App';

            % Create UIAxesRawSignal
            app.UIAxesRawSignal = uiaxes(app.UIFigure);
            title(app.UIAxesRawSignal, 'Raw Signal')
            xlabel(app.UIAxesRawSignal, 'Time')
            ylabel(app.UIAxesRawSignal, 'Voltage(mv)')
            zlabel(app.UIAxesRawSignal, 'Z')
            app.UIAxesRawSignal.ButtonDownFcn = createCallbackFcn(app, @UIAxesRawSignalButtonDown, true);
            app.UIAxesRawSignal.Position = [16 413 445 298];

            % Create UIAxesRawSpectrum
            app.UIAxesRawSpectrum = uiaxes(app.UIFigure);
            title(app.UIAxesRawSpectrum, 'Raw Signal''s Spectrum')
            xlabel(app.UIAxesRawSpectrum, 'frequency(Khz)')
            ylabel(app.UIAxesRawSpectrum, 'Amplitude')
            zlabel(app.UIAxesRawSpectrum, 'Z')
            app.UIAxesRawSpectrum.ButtonDownFcn = createCallbackFcn(app, @UIAxesRawSpectrumButtonDown, true);
            app.UIAxesRawSpectrum.Position = [483 413 455 301];

            % Create UIAxesFilteredSignal
            app.UIAxesFilteredSignal = uiaxes(app.UIFigure);
            title(app.UIAxesFilteredSignal, 'Filtered Signal ')
            xlabel(app.UIAxesFilteredSignal, 'Time')
            ylabel(app.UIAxesFilteredSignal, 'Voltage(mv)')
            zlabel(app.UIAxesFilteredSignal, 'Z')
            app.UIAxesFilteredSignal.ButtonDownFcn = createCallbackFcn(app, @UIAxesFilteredSignalButtonDown, true);
            app.UIAxesFilteredSignal.Position = [16 131 445 283];

            % Create UIAxesFilteredSpectrum
            app.UIAxesFilteredSpectrum = uiaxes(app.UIFigure);
            title(app.UIAxesFilteredSpectrum, 'Filtered Signal''s Spectrum')
            xlabel(app.UIAxesFilteredSpectrum, 'frequency(Khz)')
            ylabel(app.UIAxesFilteredSpectrum, 'Amplitude')
            zlabel(app.UIAxesFilteredSpectrum, 'Z')
            app.UIAxesFilteredSpectrum.ButtonDownFcn = createCallbackFcn(app, @UIAxesFilteredSpectrumButtonDown, true);
            app.UIAxesFilteredSpectrum.Position = [483 131 455 270];

            % Create StartStopButton
            app.StartStopButton = uibutton(app.UIFigure, 'push');
            app.StartStopButton.ButtonPushedFcn = createCallbackFcn(app, @StartStopButtonPushed, true);
            app.StartStopButton.Position = [710 78 142 44];
            app.StartStopButton.Text = 'Start/Stop';

            % Create FilterTypeDropDownLabel
            app.FilterTypeDropDownLabel = uilabel(app.UIFigure);
            app.FilterTypeDropDownLabel.HorizontalAlignment = 'right';
            app.FilterTypeDropDownLabel.Position = [16 90 61 22];
            app.FilterTypeDropDownLabel.Text = 'Filter Type';

            % Create FilterTypeDropDown
            app.FilterTypeDropDown = uidropdown(app.UIFigure);
            app.FilterTypeDropDown.Items = {'lowpass', 'highpass'};
            app.FilterTypeDropDown.DropDownOpeningFcn = createCallbackFcn(app, @FilterTypeDropDownOpening, true);
            app.FilterTypeDropDown.Position = [92 90 199 22];
            app.FilterTypeDropDown.Value = 'lowpass';

            % Create CutFrequencyEditFieldLabel
            app.CutFrequencyEditFieldLabel = uilabel(app.UIFigure);
            app.CutFrequencyEditFieldLabel.HorizontalAlignment = 'right';
            app.CutFrequencyEditFieldLabel.Position = [359 90 84 22];
            app.CutFrequencyEditFieldLabel.Text = 'Cut Frequency';

            % Create CutFrequencyEditField
            app.CutFrequencyEditField = uieditfield(app.UIFigure, 'numeric');
            app.CutFrequencyEditField.ValueChangedFcn = createCallbackFcn(app, @CutFrequencyEditFieldValueChanged, true);
            app.CutFrequencyEditField.Position = [458 90 100 22];

            % Create LampLabel
            app.LampLabel = uilabel(app.UIFigure);
            app.LampLabel.HorizontalAlignment = 'right';
            app.LampLabel.Position = [866 90 35 22];
            app.LampLabel.Text = 'Lamp';

            % Create Lamp
            app.Lamp = uilamp(app.UIFigure);
            app.Lamp.Position = [916 90 20 20];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = app1_exported

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