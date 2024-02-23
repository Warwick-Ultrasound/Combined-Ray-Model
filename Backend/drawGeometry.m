function drawGeometry(g, varargin)
    % Draws the geometry in the input struct for checking. Set 2nd element
    % to 'off' to not create a new figure.

    if ~isempty(varargin)
        if varargin ~= "off"
            figure;
        end
    end
    
    % plot pipe boundaries
    yline(g.pipeIntTop/1E-3, 'k--');
    yline(g.pipeIntBot/1E-3, 'k--');
    yline(g.pipeExtTop/1E-3, 'k-');
    yline(g.pipeExtBot/1E-3, 'k-');

    % plot piezos
    hold on;
    plot(g.piezoLeftBounds.x/1E-3, g.piezoLeftBounds.y/1E-3, 'k-');
    plot(g.piezoRightBounds.x/1E-3, g.piezoRightBounds.y/1E-3, 'k-');
    hold off;

end