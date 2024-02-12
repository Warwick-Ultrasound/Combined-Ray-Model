function [A, theta] = SSslip(m1, m2, theta0, f, inType)
    % Calculates the reflected and transmitted amplitudes following Kuhn
    % and Lutch (1961), considering that there is a layer of liquid between
    % the two solids preventing the transmission of shear stresses. 

    % convert to papers parameter names
    alpha = m1.clong;
    alphap = m2.clong;
    beta = m1.cshear;
    betap = m2.cshear;
    rho = m1.rho;
    rhop = m2.rho;
    if inType == "long" 
        c_inc = m1.clong; % set incidence velocity
        A1 = 1; % incidence longitudinal amplitude
        B1 = 0; % incidence shear amplitude
    else
        c_inc = m1.cshear;
        A1 = 0;
        B1 = 1;
    end

    % calculate a,b,c 
    c = alpha/sind(theta0);
    a = sqrt(c^2/alpha^2 - 1);
    b = sqrt(c^2/beta^2 - 1);

    % calculate critical angles
    ic1 = asind(c_inc/alphap);
    ic2 = asind(c_inc/betap);
    if ~isreal(ic1) % ensure that if theres not a critical angle we set it to 90 so it never gets hit
        ic1 = 90;
    end
    if ~isreal(ic2)
        ic2 = 90;
    end

    % calculate ap and bp
    if theta0<ic1
        ap = sqrt(c^2/alphap^2 - 1);
    else
        ap = -1i*sqrt(1 - c^2/alphap^2);
    end
    if theta0<ic2
        bp = sqrt(c^2/betap^2 - 1);
    else
        bp = -1i*sqrt(1 - c^2/betap^2);
    end

    % calculate delta, deltap, kappa
    delta = (b^2-1)^2/(2*a) + 2*b;
    deltap = (bp^2-1)^2/(2*ap) + 2*bp;
    kappa = rhop*betap^4/(rho*beta^4);

    % calculate amplitudes - these are "potential amplitudes"
    A2 = (1-(b^2-1)^2 / (a*(delta+kappa*deltap))) * A1      +      2*b*(b^2-1) / (a*(delta+kappa*deltap)) * B1; % reflected longitudinal
    B2 = -2*(b^2-1) / (delta+kappa*deltap) * A1             -      (1 - 4*b/(delta+kappa*deltap)) * B1; % reflected shear
    Ap = (betap^2/beta^2) * (b^2-1)*(bp^2-1) / (ap*(delta+kappa*deltap)) * A1     -     betap^2/beta^2 * 2*b * (bp^2-1)/(ap*(delta+kappa*deltap)) * B1; % refracted long
    Bp = -betap^2/beta^2 * 2*(b^2-1) / (delta+kappa*deltap) * A1                +     betap^2/beta^2 * 4*b / (delta+kappa*deltap) * B1; % refracted shear

    % convert to actual amplitude - differential of potential
    w = 2*pi*f; % angular frequency
    A2 = 1i*w*A2/m1.clong;
    B2 = 1i*w*B2/m1.cshear;
    Ap = 1i*w*Ap/m2.clong;
    Bp = 1i*w*Bp/m2.cshear;

    % scale wrt to the inbound wave
    Ain = 1i*w*1/c_inc; % amplitude of wave into boundary. displ. amp. is always 1
    A = abs([A2, B2, Ap, Bp]/Ain); % RL, RS, TL, TS

    % calculate angles
    theta = nan(size(A));
    theta(1) = asind(m1.clong/c_inc * sind(theta0)); % reflected longitudinal angle
    theta(2) = asind(m1.cshear/c_inc * sind(theta0)); % reflected shear angle
    theta(3) = asind(m2.clong/c_inc * sind(theta0)); % transmitted longitudinal angle
    theta(4) = asind(m2.cshear/c_inc * sind(theta0)); % transmitted shear angle
    for ii = 1:4
        if ~isreal(theta(ii))
            theta(ii) = nan; % if turned out imag, are beyond critical angle.
        end
    end

end