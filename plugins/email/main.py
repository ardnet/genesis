from genesis.ui import *
from genesis.api import *
from genesis import apis

class MailPlugin(apis.services.ServiceControlPlugin):
    text = 'Mailserver'
    iconfont = 'gen-envelop'
    folder = 'servers'

    def on_session_start(self):
        self._chpasswd = None
        self._addbox = None
        self._addalias = None
        self._adddom = None
        self._list = None
        self._config = backend.MailConfig(self.app)
        self._mc = backend.MailControl()
        self._config.load()

    def on_init(self):
        self._boxes = self._mc.list_mailboxes()
        self._aliases = self._mc.list_aliases()
        self._domains = self._mc.list_domains()

    def get_main_ui(self):
        ui = self.app.inflate('email:main')

        t = ui.find('list')
        for x in self._domains:
            t.append(UI.DTR(
                UI.Iconfont(iconfont='gen-code'),
                UI.Label(text=x),
                UI.HContainer(
                    UI.TipIcon(iconfont='gen-cancel-circle', id='deldom/'+str(self._domains.index(x)), text='Delete Domain',
                        warning='Are you sure you want to delete mail domain %s?'%x),
                ),
            ))

        if self._addbox:
            doms = [UI.SelectOption(text=x, value=x) for x in self._domains]
            ui.append('main',
                UI.DialogBox(
                    UI.FormLine(
                        UI.TextInput(name='acct', id='acct'),
                        text='Name'
                    ),
                    UI.FormLine(
                        UI.Select(*doms if doms else 'None', id='dom', name='dom'),
                        text='Domain'
                    ),
                    UI.FormLine(
                        UI.EditPassword(id='passwd', value='Click to add password'),
                        text='Password'
                    ),
                    id='dlgAddBox')
                )

        if self._adddom:
            ui.append('main',
                UI.InputBox(id='dlgAddDom', text='Enter domain name to add'))

        if self._chpasswd:
            ui.append('main',
                UI.DialogBox(
                    UI.FormLine(
                        UI.EditPassword(id='chpasswd', value='Click to change password'),
                        text='Password'
                    ),
                    id='dlgChpasswd')
                )

        return ui

    @event('button/click')
    def on_click(self, event, params, vars = None):
        if params[0] == 'add':
            self._addbox = True
        elif params[0] == 'addalias':
            self._addalias = True
        elif params[0] == 'adddom':
            self._adddom = True
        elif params[0] == 'edit':
            self._chpasswd = self._boxes[int(params[1])]
        elif params[0] == 'delbox':
            try:
                u = self._boxes[int(params[1])]
                self._mc.del_mailbox(u['name'], u['domain'])
                self.put_message('info', 'Mailbox deleted successfully')
            except Exception, e:
                self.app.log.error('Mailbox could not be deleted. Error: %s' % str(e))
                self.put_message('err', 'Mailbox could not be deleted')
        elif params[0] == 'delal':
            try:
                u = self._aliases[int(params[1])]
                self._mc.del_alias(u['name'], u['domain'], u['forward'])
                self.put_message('info', 'Alias deleted successfully')
            except Exception, e:
                self.app.log.error('Alias could not be deleted. Error: %s' % str(e))
                self.put_message('err', 'Alias could not be deleted')
        elif params[0] == 'deldom':
            for x in self._boxes + self._aliases:
                if x['domain'] == self._domains[int(params[1])]:
                    self.put_message('err', 'You still have mailboxes or aliases attached to this domain. Remove them before deleting the domain!')
                    break
            else:
                self._mc.del_domain(self._domains[int(params[1])])
                self.put_message('info', 'Domain deleted')

    @event('dialog/submit')
    @event('form/submit')
    def on_submit(self, event, params, vars=None):
        if params[0] == 'dlgAddBox':
            acct = vars.getvalue('acct', '')
            dom = vars.getvalue('dom', '')
            passwd = vars.getvalue('passwd', '')
            if vars.getvalue('action', '') == 'OK':
                m = re.match('([-0-9a-zA-Z.+_]+)', acct)
                if not acct or not m:
                    self.put_message('err', 'Must choose a valid mailbox name')
                elif (acct, dom) in self._boxes:
                    self.put_message('err', 'You already have a mailbox with this name on this domain')
                elif not passwd:
                    self.put_message('err', 'Must choose a password')
                elif passwd != vars.getvalue('passwdb',''):
                    self.put_message('err', 'Passwords must match')
                else:
                    try:
                        self._uc.add_mailbox(acct, dom, passwd)
                        self.put_message('info', 'Mailbox added successfully')
                    except Exception, e:
                        self.app.log.error('Mailbox %s@%s could not be added. Error: %s' % (acct,dom,str(e)))
                        self.put_message('err', 'Mailbox could not be added')
            self._addbox = None
        elif params[0] == 'dlgAddDom':
            v = vars.getvalue('value', '')
            if vars.getvalue('action', '') == 'OK':
                if not v or not re.match('([-0-9a-zA-Z.+_]+\.[a-zA-Z]{2,4})', v):
                    self.put_message('err', 'Must enter a valid domain to add')
                elif v in self._domains:
                    self.put_message('err', 'You have already added this domain!')
                else:
                    self._config.set('_VirtualHost_%s'%v, {'enabled': False})
                    self._config.save()
                    self.put_message('info', 'Domain added successfully')
            self._adddom = None
        elif params[0] == 'dlgChpasswd':
            passwd = vars.getvalue('chpasswd', '')
            if vars.getvalue('action', '') == 'OK':
                if not passwd:
                    self.put_message('err', 'Must choose a password')
                elif passwd != vars.getvalue('chpasswdb',''):
                    self.put_message('err', 'Passwords must match')
                else:
                    try:
                        self._uc.chpasswd(self._chpasswd[0], 
                            self._chpasswd[1], passwd)
                        self.put_message('info', 'Password changed successfully')
                    except Exception, e:
                        self.app.log.error('XMPP password for %s@%s could not be changed. Error: %s' % (self._chpasswd[0],self._chpasswd[1],str(e)))
                        self.put_message('err', 'Password could not be changed')
            self._chpasswd = None
