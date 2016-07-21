% Created by Lorenzo F. Antunes(lorenzofantunes or lfantunes)
% 20/07/2016
% Pelotas, Brazil

% Initialize model variables
delTim    = 60*60;  % time step
retVal    = 0;
flaWri    = 0;
flaRea    = 0;
simTimWri = 0;
simTimRea = 0;

%considering 8 actuators and 9 variables from EnergyPlus
controlVector = [1 1 1 1 1 1 0 0]; %Values to write on bcvtb
ePlusOutVector = [0 0 0 0 0 0 0 0 0]; %Values read from bcvtb

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add path to BCVTB matlab libraries
addpath( strcat(getenv('BCVTB_HOME'), '/lib/matlab'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Establish the socket connection
sockfd = establishClientSocket('socket.cfg');
if sockfd < 0
    fprintf('Error: Failed to obtain socket file descriptor. sockfd=%d.\n', sockfd);
    exit;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loop for simulation time steps.
simulate = 1;

%start the socket
t = tcpip('localhost', 10000);
fopen(t);

while (simulate)
    % Assign values to be exchanged.
    try

        [retVal, flaRea, simTimRea, ePlusOutVector] = exchangeDoublesWithSocket(sockfd, flaWri, length(ePlusOutVector), simTimWri, controlVector);

        %write data on the python socket
        fwrite(t, mat2str(ePlusOutVector));

        %read values from the python socket
        controleValues = fread(t, [1, t.BytesAvailable]);
        controleValues = str2num(char(controleValues));

        while (length(controleValues) == 0)
            controleValues = fread(t, [1, t.BytesAvailable]);
            controleValues = str2num(char(controleValues));
        end

        %disp(controleValues);

    catch ME1
        % exchangeDoublesWithSocket had an error. Terminate the connection
        disp(['Error: ', ME1.message])
        sendClientError(sockfd, -1);
        closeIPC(sockfd);
        rethrow(ME1)
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Check return flags
    if (flaRea == 1) % End of simulation
        disp('Matlab received end of simulation flag from BCVTB. Exit simulation.');
        closeIPC(sockfd);
        simulate=false;
    end

    if (retVal < 0) % Error during data exchange
        fprintf('Error: exchangeDoublesWithSocket has return value %d', retVal);
        sendClientError(sockfd, -1);
        closeIPC(sockfd);
        simulate=false;
    end

    if (flaRea > 1) % BCVTB requests termination due to an error.
        fprintf('Error: BCVTB requested termination of the simulation by sending %d\n Exit simulation.', retVal);
        sendClientError(sockfd, -1);
        closeIPC(sockfd);
        simulate=false;
    end

    if (simulate)
        %do whatever you want to.

        simTimWri = simTimWri + delTim;
    end
end

fclose(t);

exit
