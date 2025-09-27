%% Conway Game of Life - One Cell (Simulink auto-build)
% Builds two models:
% 1) gol_cell_cl        : combinational CL only (n0..n7, Q -> E)
% 2) gol_cell_with_ff   : CL + EN + DFF (Q_next), ready for synchronous update

function build_gol_cell_models
    build_gol_cell_cl();
    build_gol_cell_with_ff();
    disp('Done. Open models: gol_cell_cl, gol_cell_with_ff');
end

%% ---------- Model 1: CL only (E = (N==3) || (Q && (N==2))) ----------
function build_gol_cell_cl()
    mdl = 'gol_cell_cl';
    new_or_clean(mdl);

    open_system(mdl);

    %--- Helper positions (just for readability) ---
    x0 = 30; y0 = 30; dx = 80; dy = 40;

    % Inports: n0..n7, Q
    nin = 8;
    ports = strings(1, nin+1);
    for k=1:nin
        ports(k) = sprintf('n%d', k-1);
        add_block('simulink/Sources/In1', [mdl '/' char(ports(k))], ...
                  'Position', [x0, y0+(k-1)*dy, x0+30, y0+(k-1)*dy+20]);
        % (Optional) enforce type as ufix1 via Data Type Conversion if needed in your env
    end
    ports(end) = "Q";
    add_block('simulink/Sources/In1', [mdl '/Q'], ...
              'Position', [x0, y0+nin*dy+40, x0+30, y0+nin*dy+60]);

    % Sum block for N = n0+...+n7
    add_block('simulink/Math Operations/Sum', [mdl '/Sum_N'], ...
        'Inputs', repmat('+',1,nin), ...
        'IconShape', 'rectangular', ...
        'Position', [x0+180, y0+3*dy, x0+230, y0+3*dy+20], ...
        'AccumDataTypeStr', 'fixdt(0,4,0)', ...   % ufix4
        'OutDataTypeStr',   'fixdt(0,4,0)', ...
        'SaturateOnIntegerOverflow', 'off');

    % Wire neighbors to Sum_N
    for k=1:nin
        add_line(mdl, sprintf('n%d/1',k-1), sprintf('Sum_N/%d',k), 'autorouting','on');
    end

    % Relational operators: N==2, N==3
    add_block('simulink/Logic and Bit Operations/Relational Operator', [mdl '/eq2'], ...
        'Operator','==', 'Position', [x0+300, y0+2*dy, x0+360, y0+2*dy+20], ...
        'OutDataTypeStr','boolean');
    add_block('simulink/Logic and Bit Operations/Relational Operator', [mdl '/eq3'], ...
        'Operator','==', 'Position', [x0+300, y0+4*dy, x0+360, y0+4*dy+20], ...
        'OutDataTypeStr','boolean');

    % Constants 2 and 3 (ufix4)
    add_block('simulink/Sources/Constant', [mdl '/C2'], ...
        'Value','2','OutDataTypeStr','fixdt(0,4,0)', ...
        'Position',[x0+260, y0+2*dy, x0+290, y0+2*dy+20]);
    add_block('simulink/Sources/Constant', [mdl '/C3'], ...
        'Value','3','OutDataTypeStr','fixdt(0,4,0)', ...
        'Position',[x0+260, y0+4*dy, x0+290, y0+4*dy+20]);

    % Connect Sum_N to eq2/eq3; constants to eq2/eq3
    add_line(mdl,'Sum_N/1','eq2/1','autorouting','on');
    add_line(mdl,'C2/1','eq2/2','autorouting','on');
    add_line(mdl,'Sum_N/1','eq3/1','autorouting','on');
    add_line(mdl,'C3/1','eq3/2','autorouting','on');

    % Logical AND: Q && eq2
    add_block('simulink/Logic and Bit Operations/Logical Operator', [mdl '/AND_Q_eq2'], ...
        'Operator','AND','Inputs','2', ...
        'Position', [x0+420, y0+3*dy, x0+470, y0+3*dy+20]);
    add_line(mdl,'Q/1','AND_Q_eq2/1','autorouting','on');
    add_line(mdl,'eq2/1','AND_Q_eq2/2','autorouting','on');

    % Logical OR: eq3 || (Q && eq2) -> E
    add_block('simulink/Logic and Bit Operations/Logical Operator', [mdl '/OR_E'], ...
        'Operator','OR','Inputs','2', ...
        'Position', [x0+520, y0+3*dy, x0+570, y0+3*dy+20]);
    add_line(mdl,'eq3/1','OR_E/1','autorouting','on');
    add_line(mdl,'AND_Q_eq2/1','OR_E/2','autorouting','on');

    % Outport E
    add_block('simulink/Sinks/Out1', [mdl '/E'], ...
        'Position', [x0+630, y0+3*dy, x0+660, y0+3*dy+20]);
    add_line(mdl,'OR_E/1','E/1','autorouting','on');

    save_system(mdl);
end

%% ---------- Model 2: CL + EN + DFF (Q_next) ----------
function build_gol_cell_with_ff()
    mdl = 'gol_cell_with_ff';
    new_or_clean(mdl);
    open_system(mdl);

    x0 = 30; y0 = 30; dx = 80; dy = 40;
    nin = 8;

    % Inports: n0..n7, Q, EN
    for k=1:nin
        add_block('simulink/Sources/In1', [mdl sprintf('/n%d',k-1)], ...
                  'Position', [x0, y0+(k-1)*dy, x0+30, y0+(k-1)*dy+20]);
    end
    add_block('simulink/Sources/In1', [mdl '/Q'], ...
              'Position', [x0, y0+nin*dy+40, x0+30, y0+nin*dy+60]);
    add_block('simulink/Sources/In1', [mdl '/EN'], ...
              'Position', [x0, y0+nin*dy+100, x0+30, y0+nin*dy+120]);

    % Sum for N (ufix4)
    add_block('simulink/Math Operations/Sum', [mdl '/Sum_N'], ...
        'Inputs', repmat('+',1,nin), ...
        'IconShape', 'rectangular', ...
        'Position', [x0+180, y0+3*dy, x0+230, y0+3*dy+20], ...
        'AccumDataTypeStr', 'fixdt(0,4,0)', ...
        'OutDataTypeStr',   'fixdt(0,4,0)', ...
        'SaturateOnIntegerOverflow', 'off');
    for k=1:nin
        add_line(mdl, sprintf('n%d/1',k-1), sprintf('Sum_N/%d',k), 'autorouting','on');
    end

    % Comparators
    add_block('simulink/Logic and Bit Operations/Relational Operator', [mdl '/eq2'], ...
        'Operator','==', 'Position', [x0+300, y0+2*dy, x0+360, y0+2*dy+20], ...
        'OutDataTypeStr','boolean');
    add_block('simulink/Logic and Bit Operations/Relational Operator', [mdl '/eq3'], ...
        'Operator','==', 'Position', [x0+300, y0+4*dy, x0+360, y0+4*dy+20], ...
        'OutDataTypeStr','boolean');
    add_block('simulink/Sources/Constant', [mdl '/C2'], ...
        'Value','2','OutDataTypeStr','fixdt(0,4,0)', ...
        'Position',[x0+260, y0+2*dy, x0+290, y0+2*dy+20]);
    add_block('simulink/Sources/Constant', [mdl '/C3'], ...
        'Value','3','OutDataTypeStr','fixdt(0,4,0)', ...
        'Position',[x0+260, y0+4*dy, x0+290, y0+4*dy+20]);

    add_line(mdl,'Sum_N/1','eq2/1','autorouting','on');
    add_line(mdl,'C2/1','eq2/2','autorouting','on');
    add_line(mdl,'Sum_N/1','eq3/1','autorouting','on');
    add_line(mdl,'C3/1','eq3/2','autorouting','on');

    % E = (N==3) || (Q && (N==2))
    add_block('simulink/Logic and Bit Operations/Logical Operator', [mdl '/AND_Q_eq2'], ...
        'Operator','AND','Inputs','2', ...
        'Position', [x0+420, y0+3*dy, x0+470, y0+3*dy+20]);
    add_line(mdl,'Q/1','AND_Q_eq2/1','autorouting','on');
    add_line(mdl,'eq2/1','AND_Q_eq2/2','autorouting','on');

    add_block('simulink/Logic and Bit Operations/Logical Operator', [mdl '/OR_E'], ...
        'Operator','OR','Inputs','2', ...
        'Position', [x0+520, y0+3*dy, x0+570, y0+3*dy+20]);
    add_line(mdl,'eq3/1','OR_E/1','autorouting','on');
    add_line(mdl,'AND_Q_eq2/1','OR_E/2','autorouting','on');

    % Switch for EN: E_final = EN ? E : Q
    add_block('simulink/Signal Routing/Switch', [mdl '/SW_EN'], ...
        'Threshold','0.5', 'Criteria','u2 >= Threshold', ... % boolean EN ok
        'Position',[x0+600, y0+3*dy-10, x0+640, y0+3*dy+30]);
    % Connect: u2=EN (control), u1=E (true), u3=Q (false)
    add_line(mdl,'OR_E/1','SW_EN/1','autorouting','on');   % true
    add_line(mdl,'EN/1','SW_EN/2','autorouting','on');     % control
    add_line(mdl,'Q/1','SW_EN/3','autorouting','on');      % false

    % Unit Delay as DFF: Q_next <= E_final
    add_block('simulink/Discrete/Unit Delay', [mdl '/DFF'], ...
        'Position',[x0+680, y0+3*dy, x0+720, y0+3*dy+20], ...
        'SampleTime','-1'); % inherit
    add_line(mdl,'SW_EN/1','DFF/1','autorouting','on');

    % Outports: E (for debug) and Q_next
    add_block('simulink/Sinks/Out1', [mdl '/E'], ...
        'Position', [x0+630, y0+4.5*dy, x0+660, y0+4.5*dy+20]);
    add_line(mdl,'OR_E/1','E/1','autorouting','on');

    add_block('simulink/Sinks/Out1', [mdl '/Q_next'], ...
        'Position', [x0+740, y0+3*dy, x0+770, y0+3*dy+20]);
    add_line(mdl,'DFF/1','Q_next/1','autorouting','on');

    save_system(mdl);
end

%% ---------- Utility ----------
function new_or_clean(mdl)
    if bdIsLoaded(mdl)
        close_system(mdl,0);
    end
    if exist([mdl '.slx'],'file'), delete([mdl '.slx']); end
    new_system(mdl);
end
