<%inherit file="../layouts/main.mako"/>
<%!
    import re
    import calendar

    import sickrage
    from sickrage.core.helpers import srdatetime
    from sickrage.core.updaters import tz_updater
    from sickrage.core.media.util import showImage
%>
<%block name="metas">
    <meta data-var="max_download_count" data-content="${max_download_count}">
</%block>
<%block name="content">
    <%namespace file="../includes/quality_defaults.mako" import="renderQualityPill"/>
    <div class="row">
        <div class="col-xs-12 text-center">
            % if sickrage.srCore.srConfig.HOME_LAYOUT != 'poster':
                <label for="popover" class="badge">Select Columns:
                    <button id="popover" type="button" class="form-control form-control-inline input-sm"><b class="caret"></b></button>
                </label>
            % endif

            % if sickrage.srCore.srConfig.HOME_LAYOUT == 'poster':
                <label for="postersort" class="badge">Sort By:
                    <select id="postersort" class="form-control form-control-inline input-sm">
                        <option value="name"
                                data-sort="${srWebRoot}/setPosterSortBy/?sort=name" ${('', 'selected="selected"')[sickrage.srCore.srConfig.POSTER_SORTBY == 'name']}>
                            Name
                        </option>
                        <option value="date"
                                data-sort="${srWebRoot}/setPosterSortBy/?sort=date" ${('', 'selected="selected"')[sickrage.srCore.srConfig.POSTER_SORTBY == 'date']}>
                            Next Episode
                        </option>
                        <option value="network"
                                data-sort="${srWebRoot}/setPosterSortBy/?sort=network" ${('', 'selected="selected"')[sickrage.srCore.srConfig.POSTER_SORTBY == 'network']}>
                            Network
                        </option>
                        <option value="progress"
                                data-sort="${srWebRoot}/setPosterSortBy/?sort=progress" ${('', 'selected="selected"')[sickrage.srCore.srConfig.POSTER_SORTBY == 'progress']}>
                            Progress
                        </option>
                    </select>
                </label>

                <label for="postersortdirection" class="badge">Sort Order:
                    <select id="postersortdirection" class="form-control form-control-inline input-sm">
                        <option value="true"
                                data-sort="${srWebRoot}/setPosterSortDir/?direction=1" ${('', 'selected="selected"')[sickrage.srCore.srConfig.POSTER_SORTDIR == 1]}>
                            Asc
                        </option>
                        <option value="false"
                                data-sort="${srWebRoot}/setPosterSortDir/?direction=0" ${('', 'selected="selected"')[sickrage.srCore.srConfig.POSTER_SORTDIR == 0]}>
                            Desc
                        </option>
                    </select>
                </label>
            % endif

            <label for="layout" class="badge">Layout:
                <select id="layout" name="layout" class="form-control form-control-inline input-sm" onchange="location = this.options[this.selectedIndex].value;">
                    <option value="${srWebRoot}/setHomeLayout/?layout=poster" ${('', 'selected="selected"')[sickrage.srCore.srConfig.HOME_LAYOUT == 'poster']}>
                        Poster
                    </option>
                    <option value="${srWebRoot}/setHomeLayout/?layout=small" ${('', 'selected="selected"')[sickrage.srCore.srConfig.HOME_LAYOUT == 'small']}>
                        Small Poster
                    </option>
                    <option value="${srWebRoot}/setHomeLayout/?layout=banner" ${('', 'selected="selected"')[sickrage.srCore.srConfig.HOME_LAYOUT == 'banner']}>
                        Banner
                    </option>
                    <option value="${srWebRoot}/setHomeLayout/?layout=simple" ${('', 'selected="selected"')[sickrage.srCore.srConfig.HOME_LAYOUT == 'simple']}>
                        Simple
                    </option>
                </select>
            </label>
        </div>
    </div>

    % for curShowlist in showlists:
        <% curListType = curShowlist[0] %>
        <% myShowList = list(curShowlist[1]) %>
        % if curListType == "Anime":
            <h1 class="header">Anime List</h1>
        % endif
        % if sickrage.srCore.srConfig.HOME_LAYOUT == 'poster':
            <div id="${('container', 'container-anime')[curListType == 'Anime' and sickrage.srCore.srConfig.HOME_LAYOUT == 'poster']}" class="clearfix">
                % for curLoadingShow in sickrage.srCore.SHOWQUEUE.loadingShowList:
                    % if not curLoadingShow.show:
                        <div class="show-container" data-name="0" data-date="010101" data-network="0" data-progress="101">
                            <img alt="" title="${curLoadingShow.show_name}" class="show-image"
                                 style="border-bottom: 1px solid #111;" src="${srWebRoot}/images/poster.png"/>
                            <div class="show-details">
                                <div class="show-add">Loading... (${curLoadingShow.show_name})</div>
                            </div>
                        </div>
                    % endif
                % endfor

                <% myShowList.sort(lambda x, y: cmp(x.name, y.name)) %>
                % for curShow in myShowList:
                    <%
                        cur_airs_next = ''
                        cur_snatched = 0
                        cur_downloaded = 0
                        cur_total = 0
                        download_stat_tip = ''
                        display_status = curShow.status

                        if display_status:
                            if re.search(r'(?i)(?:new|returning)\s*series', curShow.status):
                                display_status = 'Continuing'
                            elif re.search(r'(?i)(?:nded)', curShow.status):
                                display_status = 'Ended'

                        if curShow.indexerid in show_stat:
                            cur_airs_next = show_stat[curShow.indexerid]['ep_airs_next']

                            cur_snatched = show_stat[curShow.indexerid]['ep_snatched']
                            if not cur_snatched:
                                cur_snatched = 0

                            cur_downloaded = show_stat[curShow.indexerid]['ep_downloaded']
                            if not cur_downloaded:
                                cur_downloaded = 0

                            cur_total = show_stat[curShow.indexerid]['ep_total']
                            if not cur_total:
                                cur_total = 0

                        if cur_total != 0:
                            download_stat = str(cur_downloaded)
                            download_stat_tip = "Downloaded: " + str(cur_downloaded)
                            if cur_snatched > 0:
                                download_stat = download_stat
                                download_stat_tip = download_stat_tip + "&#013;" + "Snatched: " + str(cur_snatched)

                            download_stat = download_stat + " / " + str(cur_total)
                            download_stat_tip = download_stat_tip + "&#013;" + "Total: " + str(cur_total)
                        else:
                            download_stat = '?'
                            download_stat_tip = "no data"

                        nom = cur_downloaded
                        den = cur_total
                        if den == 0:
                            den = 1

                        progressbar_percent = nom * 100 / den

                        data_date = '6000000000.0'
                        if cur_airs_next:
                            data_date = calendar.timegm(srdatetime.srDateTime.convert_to_setting(tz_updater.parse_date_time(cur_airs_next, curShow.airs, curShow.network)).timetuple())
                        elif display_status:
                            if 'nded' not in display_status and 1 == int(curShow.paused):
                                data_date = '5000000500.0'
                            elif 'ontinu' in display_status:
                                data_date = '5000000000.0'
                            elif 'nded' in display_status:
                                data_date = '5000000100.0'
                    %>
                    <div class="show-container" id="show${curShow.indexerid}" data-name="${curShow.name}" data-date="${data_date}" data-network="${curShow.network}" data-progress="${progressbar_percent}">
                        <div class="show-image">
                            <a href="${srWebRoot}/home/displayShow?show=${curShow.indexerid}"><img alt="" class="show-image" src="${srWebRoot}${showImage(curShow.indexerid, 'poster_thumb')}" /></a>
                        </div>

                        <div class="progressbar" style="position:relative;" data-show-id="${curShow.indexerid}" data-progress-percentage="${progressbar_percent}"></div>

                        <div class="show-title">
                            ${curShow.name}
                        </div>

                        <div class="show-date">
                            % if cur_airs_next:
                                <% ldatetime = srdatetime.srDateTime.convert_to_setting(tz_updater.parse_date_time(cur_airs_next, curShow.airs, curShow.network)) %>
                                <%
                                    try:
                                        out = srdatetime.srDateTime.srfdate(ldatetime)
                                    except ValueError:
                                        out = 'Invalid date'
                                        pass
                                %>
                                    ${out}
                            % else:
                                <%
                                output_html = '?'
                                display_status = curShow.status
                                if display_status:
                                    if 'nded' not in display_status and 1 == int(curShow.paused):
                                      output_html = 'Paused'
                                    elif display_status:
                                        output_html = display_status
                                %>
                                ${output_html}
                            % endif
                        </div>

                        <table width="100%" cellspacing="1" border="0" cellpadding="0">
                            <tr>
                                <td class="show-table">
                                    <span class="show-dlstats" title="${download_stat_tip}">${download_stat}</span>
                                </td>

                                <td class="show-table">
                                    % if sickrage.srCore.srConfig.HOME_LAYOUT != 'simple':
                                        % if curShow.network:
                                            <span title="${curShow.network}"><img class="show-network-image" src="${srWebRoot}${showImage(curShow.indexerid, 'network')}" alt="${curShow.network}" title="${curShow.network}" /></span>
                                        % else:
                                            <span title="No Network"><img class="show-network-image" src="${srWebRoot}/images/network/nonetwork.png" alt="No Network" title="No Network" /></span>
                                        % endif
                                    % else:
                                        <span title="${curShow.network}">${curShow.network}</span>
                                    % endif
                                </td>

                                <td class="show-table">
                                    ${renderQualityPill(curShow.quality, showTitle=True, overrideClass="show-quality")}
                                </td>
                            </tr>
                        </table>
                    </div>
                % endfor
            </div>
        % else:
            <table id="showListTable${curListType}" class="sickrageTable tablesorter" cellspacing="1" border="0" cellpadding="0">
                <thead>
                    <tr>
                        <th class="nowrap">Next Ep</th>
                        <th class="nowrap">Prev Ep</th>
                        <th>Show</th>
                        <th>Network</th>
                        <th>Quality</th>
                        <th>Downloads</th>
                        <th>Active</th>
                        <th>Status</th>
                    </tr>
                </thead>

                <tfoot>
                    <tr>
                        <th rowspan="1" colspan="1" align="center"><a href="${srWebRoot}/home/addShows/">Add ${('Show', 'Anime')[curListType == 'Anime']}</a></th>
                        <th>&nbsp;</th>
                        <th>&nbsp;</th>
                        <th>&nbsp;</th>
                        <th>&nbsp;</th>
                        <th>&nbsp;</th>
                        <th>&nbsp;</th>
                        <th>&nbsp;</th>
                    </tr>
                </tfoot>

                % if sickrage.srCore.SHOWQUEUE.loadingShowList:
                    <tbody class="tablesorter-infoOnly">
                        % for curLoadingShow in sickrage.srCore.SHOWQUEUE.loadingShowList:
                            % if not curLoadingShow.show or curLoadingShow.show not in sickrage.srCore.SHOWLIST:
                                <tr>
                                    <td align="center">(loading)</td>
                                    <td></td>
                                    <td>
                                        % if curLoadingShow.show is None:
                                            <span title="">Loading... (${curLoadingShow.show_name})</span>
                                        % else:
                                            <a data-fancybox href="displayShow?show=${curLoadingShow.show.indexerid}">${curLoadingShow.show.name}</a>
                                        % endif
                                    </td>
                                    <td></td>
                                    <td></td>
                                    <td></td>
                                    <td></td>
                                </tr>
                            % endif
                        % endfor
                    </tbody>
                % endif

                <tbody>
                    <% myShowList.sort(lambda x, y: cmp(x.name, y.name)) %>
                    % for curShow in myShowList:
                        <%
                            cur_airs_next = ''
                            cur_airs_prev = ''
                            cur_snatched = 0
                            cur_downloaded = 0
                            cur_total = 0
                            download_stat_tip = ''

                            if curShow.indexerid in show_stat:
                                cur_airs_next = show_stat[curShow.indexerid]['ep_airs_next']
                                cur_airs_prev = show_stat[curShow.indexerid]['ep_airs_prev']

                                cur_snatched = show_stat[curShow.indexerid]['ep_snatched']
                                if not cur_snatched:
                                    cur_snatched = 0

                                cur_downloaded = show_stat[curShow.indexerid]['ep_downloaded']
                                if not cur_downloaded:
                                    cur_downloaded = 0

                                cur_total = show_stat[curShow.indexerid]['ep_total']
                                if not cur_total:
                                    cur_total = 0

                            if cur_total != 0:
                                download_stat = str(cur_downloaded)
                                download_stat_tip = "Downloaded: " + str(cur_downloaded)
                                if cur_snatched > 0:
                                    download_stat = download_stat + "+" + str(cur_snatched)
                                    download_stat_tip = download_stat_tip + "&#013;" + "Snatched: " + str(cur_snatched)

                                download_stat = download_stat + " / " + str(cur_total)
                                download_stat_tip = download_stat_tip + "&#013;" + "Total: " + str(cur_total)
                            else:
                                download_stat = '?'
                                download_stat_tip = "no data"

                            nom = cur_downloaded
                            den = cur_total
                            if den == 0:
                                den = 1

                            progressbar_percent = nom * 100 / den
                        %>
                        <tr>
                            % if cur_airs_next:
                                <% airDate = srdatetime.srDateTime.convert_to_setting(tz_updater.parse_date_time(cur_airs_next, curShow.airs, curShow.network)) %>
                                % try:
                                    <td align="center" class="nowrap">
                                        <time datetime="${airDate.isoformat()}" class="date">${srdatetime.srDateTime.srfdate(airDate)}</time>
                                    </td>
                                % except ValueError:
                                    <td align="center" class="nowrap"></td>
                                % endtry
                            % else:
                                <td align="center" class="nowrap"></td>
                            % endif

                            % if cur_airs_prev:
                                <% airDate = srdatetime.srDateTime.convert_to_setting(tz_updater.parse_date_time(cur_airs_prev, curShow.airs, curShow.network)) %>
                                % try:
                                    <td align="center" class="nowrap">
                                        <time datetime="${airDate.isoformat()}" class="date">${srdatetime.srDateTime.srfdate(airDate)}</time>
                                    </td>
                                % except ValueError:
                                    <td align="center" class="nowrap"></td>
                                % endtry
                            % else:
                                <td align="center" class="nowrap"></td>
                            % endif

                            % if sickrage.srCore.srConfig.HOME_LAYOUT == 'small':
                                <td class="tvShow">
                                    <div class="imgsmallposter ${sickrage.srCore.srConfig.HOME_LAYOUT}">
                                        <a href="${srWebRoot}/home/displayShow?show=${curShow.indexerid}" title="${curShow.name}">
                                            <img src="${srWebRoot}${showImage(curShow.indexerid, 'poster_thumb')}" class="${sickrage.srCore.srConfig.HOME_LAYOUT}"
                                                 alt="${curShow.indexerid}"/>
                                        </a>
                                        <a href="${srWebRoot}/home/displayShow?show=${curShow.indexerid}" style="vertical-align: middle;">${curShow.name}</a>
                                    </div>
                                </td>
                            % elif sickrage.srCore.srConfig.HOME_LAYOUT == 'banner':
                                <td>
                                    <span style="display: none;">${curShow.name}</span>
                                    <div class="imgbanner ${sickrage.srCore.srConfig.HOME_LAYOUT}">
                                        <a href="${srWebRoot}/home/displayShow?show=${curShow.indexerid}">
                                            <img src="${srWebRoot}${showImage(curShow.indexerid, 'banner')}" class="${sickrage.srCore.srConfig.HOME_LAYOUT}"
                                                 alt="${curShow.indexerid}" title="${curShow.name}"/>
                                        </a>
                                    </div>
                                </td>
                            % elif sickrage.srCore.srConfig.HOME_LAYOUT == 'simple':
                                <td class="tvShow"><a href="${srWebRoot}/home/displayShow?show=${curShow.indexerid}">${curShow.name}</a></td>
                            % endif

                            % if sickrage.srCore.srConfig.HOME_LAYOUT != 'simple':
                                <td align="center">
                                    % if curShow.network:
                                        <span title="${curShow.network}"><img id="network" width="54" height="27" src="${srWebRoot}${showImage(curShow.indexerid, 'network')}" alt="${curShow.network}" title="${curShow.network}" /></span>
                                        <span class="visible-print-inline">${curShow.network}</span>
                                    % else:
                                        <span title="No Network"><img id="network" width="54" height="27" src="${srWebRoot}/images/network/nonetwork.png" alt="No Network" title="No Network" /></span>
                                        <span class="visible-print-inline">No Network</span>
                                    % endif
                                </td>
                            % else:
                                <td>
                                    <span title="${curShow.network}">${curShow.network}</span>
                                </td>
                            % endif

                            <td align="center">${renderQualityPill(curShow.quality, showTitle=True)}</td>

                            <td align="center">
                                <span style="display: none;">${download_stat}</span>
                                <div class="progressbar" style="position:relative" data-show-id="${curShow.indexerid}" data-progress-percentage="${progressbar_percent}" data-progress-text="${download_stat}" data-progress-tip="${download_stat_tip}"></div>
                                ## <span class="visible-print-inline">${download_stat}</span>
                            </td>

                            <td align="center">
                                <% paused = int(curShow.paused) == 0 and curShow.status == 'Continuing' %>
                                <img src="${srWebRoot}/images/${('no16.png', 'yes16.png')[bool(paused)]}" alt="${('No', 'Yes')[bool(paused)]}" width="16" height="16" />
                            </td>

                            <td align="center">
                                <% display_status = curShow.status %>
                                % if display_status and re.search(r'(?i)(?:new|returning)\s*series', curShow.status):
                                        <% display_status = 'Continuing' %>
                                % elif display_status and re.search('(?i)(?:nded)', curShow.status):
                                        <% display_status = 'Ended' %>
                                % endif
                                ${display_status}
                            </td>
                        </tr>
                    % endfor
                </tbody>
            </table>
        % endif
    % endfor
</%block>
