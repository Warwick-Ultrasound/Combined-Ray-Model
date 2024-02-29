function [signal, detectionPoints, A] = receivedSignal(paths)
    % goes through all of the individual paths in the input and adds the
    % waveforms together if they're detected to get the received signal

    signal = zeros(size(paths{1}.burst));
    detectionPoints = []; % detection points on piezo
    A = []; % pk-pk of wave incident on detectionPoints

    for ii = 1:size(paths, 1)
        for jj = 1:size(paths, 2)
            if paths{ii,jj}.detected
                signal = signal + paths{ii,jj}.burst;
                detectionPoints(end+1,:) = paths{ii,jj}.rays{end}.stop; % end point of path
                A(end+1) = max(paths{ii,jj}.burst) - min(paths{ii,jj}.burst); % amplitude of contribution
            end
        end
    end
end