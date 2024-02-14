function drawGeometry(g)
    % Draws the geometry in the input struct for checking.

    %figure;
    
    % plot pipe boundaries
    yline(g.pipeIntTop/1E-3, 'k--');
    hold on;
    yline(g.pipeIntBot/1E-3, 'k--');
    yline(g.pipeExtTop/1E-3, 'k-');
    yline(g.pipeExtBot/1E-3, 'k-');

    % plot piezos
    plot(g.piezoLeftBounds.x/1E-3, g.piezoLeftBounds.y/1E-3, 'k-');
    plot(g.piezoRightBounds.x/1E-3, g.piezoRightBounds.y/1E-3, 'k-');

    hold off;

end