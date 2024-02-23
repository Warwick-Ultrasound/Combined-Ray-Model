function c = c_PEEK(T)
    % A fucntion which calculates the speed of sound in PEEK from a
    % quadratic fit of experimental data taken in February 2022 (by me). 
    if T < 12 | T > 70
        warning("T out of range for c_PEEK, values extrapolated.");
        disp("Valid range is 12 - 70 degrees C");
    end

    p1 = 0.005498;
    p2 = -2.371;
    p3 = 2627;
    c = p1*T.^2 + p2*T + p3;

end