# J. McDonald, A. Schueth, ChatGPT: Jan 2026
import matplotlib.pyplot as plt
import matplotlib.transforms as mtransforms
import numpy as np

srgb_to_linear = lambda x: np.where(x <= 0.04045, x/12.92,((x + 0.055)/1.055)**2.4)
linear_to_srgb = lambda x: np.where(x <= 0.0031308, 12.92*x,1.055*(x**(1/2.4)) - 0.055)

def apply_sim(img, mat):
    lin = srgb_to_linear(img)
    out = lin @ mat.T
    return np.clip(linear_to_srgb(out), 0, 1)

def compute_tight_content_bbox(fig):
    """
    Returns a Bbox (in display/pixel coords) that tightly encloses
    all axes, titles, labels, and tick labels in the figure.
    """
    fig.canvas.draw()
    renderer = fig.canvas.get_renderer()
    
    bboxes = []
    
    for ax in fig.axes:
    
        # Axes frame
        bboxes.append(ax.get_window_extent())
    
        # Titles & axis labels
        for txt in (ax.title, ax.xaxis.label, ax.yaxis.label):
            if txt.get_text():
                bboxes.append(txt.get_window_extent(renderer=renderer))
    
        # Tick labels
        for tick in ax.get_xticklabels() + ax.get_yticklabels():
            if tick.get_text():
                bboxes.append(tick.get_window_extent(renderer=renderer))
    
    # Combine bboxes
    x0 = min(bb.x0 for bb in bboxes)
    y0 = min(bb.y0 for bb in bboxes)
    x1 = max(bb.x1 for bb in bboxes)
    y1 = max(bb.y1 for bb in bboxes)
    
    return mtransforms.Bbox.from_extents(x0, y0, x1, y1)

MATRICES = {
    # 1. Deuteranomaly (~2–3% of population) — MOST COMMON
    "deuteranomaly": np.array([[0.39295,  0.82361, -0.21656], [0.26341,  0.69004,  0.04655],[-0.00625, 0.04100,  0.96525]]),

    # 2. Protanomaly (~0.5%)
    "protanomaly": np.array([[0.46533,  0.86438, -0.32971],[0.19518,  0.77528,  0.02954],[0.00500, -0.02817,  1.02317]]),

    # 3. Deuteranopia (~0.5%)
    "deuteranopia": np.array([[0.367322, 0.860646, -0.227968],[0.280085, 0.672501,  0.047413],[-0.011820, 0.042940,  0.968881]]),

    # 4. Protanopia (~0.5%)
    "protanopia": np.array([[0.152286, 1.052583, -0.204868],[0.114503, 0.786281,  0.099216],[-0.003882, -0.048116, 1.051998]]),

    # 5. Tritanomaly (~0.01–0.03%)
    "tritanomaly": np.array([[1.01728,  0.02716, -0.04444],[-0.00611, 0.95899,  0.04712],[0.00212, -0.02125,  1.01913]]),

    # 6. Tritanopia (<0.01%)
    "tritanopia": np.array([[1.255528, -0.076749, -0.178779],[-0.078411, 0.930809,  0.147602],[0.004733, -0.038433,  1.033700]]),

    # 7. Achromatomaly (<0.01%)
    "achromatomaly": np.array([[0.618, 0.320, 0.062],[0.163, 0.775, 0.062],[0.163, 0.320, 0.516]]),

    # 8. Achromatopsia (~0.003%) — RAREST
    "achromatopsia": np.array([[0.299, 0.587, 0.114],[0.299, 0.587, 0.114],[0.299, 0.587, 0.114]]),

}

def colorblind_filter(obj, mode='basic', grid='on', scale=1.5, font_titlesize=24):
    ''' takes a figure object (premade in a cell or line prior) and converts it to replicate different colorblindness types.
    
    mode (str):          'basic' produces a 4 panel plot of the 4 most different looking colorblindness types.
                         'all' produces a 9 panel plot of the 8 types of colorblindess plus the original image.
                         
    grid (str):          'on' produces a square figure with embedded subplots (2x2 or 3x3 depending on mode)
                         'off' produces a single column subplot (length 4 or 9 depending on mode)
                         
    scale (float):        lets you adjust the size of the output plot based on the size of the original image (approximately). 
                          a 4 in by 4 in plot will become 6 in by 6 in if scale is 1.5. This only works for grid='on' 
                          
    font_titlesize (int): size of the title text in typical matplotlib units
                 
    to use, create a matplotlib plot and give the figure object to this function. for example:

    from ColorblindFilter import colorblind_filter
    fig = plt.figure()
    data = np.random.rand(50,50)
    plt.imshow(data)
    plt.show()
    colorblind_filter(fig, mode='all', font_titlesize=18)
    '''


    if isinstance(obj, plt.Figure):
        fig = obj
    elif isinstance(obj, plt.Axes):
        fig = obj.figure
    else:
        raise TypeError("Expected a matplotlib Figure or Axes.")
    
    fig.canvas.draw()
    w, h = fig.canvas.get_width_height()
    rgba = np.asarray(fig.canvas.buffer_rgba())  # shape (h, w, 4)
    img = rgba[:, :, :3]/255.0
    
    size = fig.get_size_inches()
    
    srgb_to_linear = lambda x: np.where(x <= 0.04045, x/12.92,((x + 0.055)/1.055)**2.4)
    linear_to_srgb = lambda x: np.where(x <= 0.0031308, 12.92*x,1.055*(x**(1/2.4)) - 0.055)
    
    dpi = fig.dpi
    
    mybox = compute_tight_content_bbox(fig)
    # add a 10% buffer
    edgex = int(w/20)
    edgey = int(h/20)
    x0=np.clip(int(mybox.x0)-edgex, 0,w) 
    x1=np.clip(int(mybox.x1)+edgex, 0,w) 
    y0=np.clip(  int(mybox.y0) - edgey,0,h)
    y1=np.clip( int(mybox.y1) + edgey,0,h)
    yt = y1/h
    
    if mode == 'all':
        if grid == 'on':  new_fig, axes = plt.subplots(3, 3, figsize=(((x1-x0)/dpi)*scale, ((y1-y0)/dpi)*scale), constrained_layout=True)
        if grid == 'off': new_fig, axes = plt.subplots(9, figsize=(((x1-x0)/dpi), ((y1-y0)/dpi)*8), constrained_layout=True)
        for i,ax in zip(range(9), axes.flatten()[:]):
            if i == 0:
                ax.imshow(img[y0:y1,x0:x1]);   ax.set_title("Original"    ,y=yt,fontsize=font_titlesize)
            else:
                form = list(MATRICES.keys())[i-1]
                img_convert = apply_sim(img, MATRICES[form])[y0:y1,x0:x1]
                ax.imshow(img_convert);   ax.set_title(form.title() ,y=yt,fontsize=font_titlesize)
            ax.axis('off')
    
    if mode == 'basic':
        if grid == 'on':  new_fig, axes = plt.subplots(2,2, figsize=(((x1-x0)/dpi)*scale, ((y1-y0)/dpi)*scale), constrained_layout=True)
        if grid == 'off': new_fig, axes = plt.subplots(4, figsize=(((x1-x0)/dpi), ((y1-y0)/dpi)*4), constrained_layout=True)
        for form,ax in zip(['deuteranomaly', 'tritanomaly', 'achromatomaly', 'achromatopsia'], axes.flatten()[:]):
        
            img_convert = apply_sim(img, MATRICES[form])[y0:y1,x0:x1]
            ax.imshow(img_convert);   ax.set_title(form.title() ,y=yt,fontsize=font_titlesize)
            ax.axis('off')
        