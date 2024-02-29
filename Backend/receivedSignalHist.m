function [Abinned, edges] = receivedSignalHist(g, detPoints, Arec, Nbins)
    % Calculates a histogram of how much ultrasound is incident upon each
    % portion of the receiving piezo along its length.

    x0 = g.piezoRightBounds.x(1); % left edge, x
    y0 = g.piezoRightBounds.y(1); % left edge, y
    x1 = g.piezoRightBounds.x(2); % right edge, x
    y1 = g.piezoRightBounds.y(2); % right edge, y
    
    % calculate length along piezo (left to right) of each reception point
    detL = sqrt( (detPoints(:,1)-x0).^2 + (detPoints(:,2)-y0).^2 );

    % bin the results
    Lmax = sqrt( (x1-x0)^2 + (y1-y0)^2 );
    edges = linspace(0, Lmax, Nbins+1);
    Abinned = nan(Nbins, 1);
    for ii = 1:Nbins
        Abinned(ii) = sum(Arec(detL>edges(ii) & detL<edges(ii+1)));
    end
end
